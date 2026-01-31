import 'dart:convert';
import 'dart:async';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zedsecure/models/v2ray_config.dart';
import 'package:zedsecure/models/subscription.dart';
import 'package:zedsecure/models/app_settings.dart';
import 'package:zedsecure/services/v2ray_config_builder.dart';
import 'package:zedsecure/services/log_service.dart';
import 'package:zedsecure/services/native_ping_service.dart';
import 'package:flutter/foundation.dart';

class V2RayService extends ChangeNotifier {
  bool _isInitialized = false;
  V2RayConfig? _activeConfig;
  V2RayStatus? _currentStatus;
  
  final Map<String, int?> _pingCache = {};
  final Map<String, bool> _pingInProgress = {};

  static final V2RayService _instance = V2RayService._internal();
  factory V2RayService() => _instance;

  late final V2ray _flutterV2ray;
  
  List<String> _customDnsServers = ['1.1.1.1', '1.0.0.1'];
  bool _useDns = true;
  String? _detectedCountryCode;

  V2RayStatus? get currentStatus => _currentStatus;
  V2RayConfig? get activeConfig => _activeConfig;
  bool get isConnected => _activeConfig != null;

  V2RayService._internal() {
    _flutterV2ray = V2ray(
      onStatusChanged: (status) {
        _currentStatus = status;
        _handleStatusChange(status);
        notifyListeners();
      },
    );
    _loadPingCache();
  }

  void _handleStatusChange(V2RayStatus status) {
    String statusString = status.toString().toLowerCase();
    if ((statusString.contains('disconnect') ||
            statusString.contains('stop') ||
            statusString.contains('idle')) &&
        _activeConfig != null) {
      _activeConfig = null;
      _clearActiveConfig();
    }
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _flutterV2ray.initialize(
        notificationIconResourceType: "mipmap",
        notificationIconResourceName: "ic_launcher",
      );
      _isInitialized = true;
      await _loadDnsSettings();
      await _tryRestoreActiveConfig();
    }
  }

  Future<void> _loadDnsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _useDns = prefs.getBool('use_custom_dns') ?? true;
    final dnsString = prefs.getString('custom_dns_servers');
    if (dnsString != null && dnsString.isNotEmpty) {
      _customDnsServers = dnsString.split(',');
    }
  }
  
  Future<void> _loadPingCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString('ping_cache');
      if (cacheJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(cacheJson);
        final now = DateTime.now().millisecondsSinceEpoch;
        decoded.forEach((key, value) {
          if (value is Map && value['ping'] != null && value['timestamp'] != null) {
            final timestamp = value['timestamp'] as int;
            if (now - timestamp < 300000) {
              _pingCache[key] = value['ping'] as int;
            }
          }
        });
        debugPrint('Loaded ${_pingCache.length} cached ping results');
      }
    } catch (e) {
      debugPrint('Error loading ping cache: $e');
    }
  }
  
  Future<void> _savePingCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> cacheData = {};
      final now = DateTime.now().millisecondsSinceEpoch;
      _pingCache.forEach((key, value) {
        if (value != null && value >= 0) {
          cacheData[key] = {
            'ping': value,
            'timestamp': now,
          };
        }
      });
      await prefs.setString('ping_cache', jsonEncode(cacheData));
    } catch (e) {
      debugPrint('Error saving ping cache: $e');
    }
  }
  
  Future<void> saveDnsSettings(bool enabled, List<String> servers) async {
    _useDns = enabled;
    _customDnsServers = servers;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_custom_dns', enabled);
    await prefs.setString('custom_dns_servers', servers.join(','));
    notifyListeners();
  }
  
  bool get useDns => _useDns;
  List<String> get dnsServers => List.from(_customDnsServers);
  String? get detectedCountryCode => _detectedCountryCode;
  String? _detectedIP;
  String? _detectedCity;
  String? _detectedRegion;
  String? get detectedIP => _detectedIP;
  String? get detectedCity => _detectedCity;
  String? get detectedRegion => _detectedRegion;

  Future<String?> detectRealCountry() async {
    try {
      final response = await http.get(
        Uri.parse('https://speed.cloudflare.com/meta'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        _detectedCountryCode = data['country']?.toString().toUpperCase();
        _detectedIP = data['clientIp']?.toString();
        _detectedCity = data['city']?.toString();
        _detectedRegion = data['region']?.toString();
        
        debugPrint('Detected: Country=$_detectedCountryCode, IP=$_detectedIP, City=$_detectedCity, Region=$_detectedRegion');
        notifyListeners();
        return _detectedCountryCode;
      }
    } catch (e) {
      debugPrint('Cloudflare meta API failed: $e');
    }
    
    final traceEndpoints = [
      'https://one.one.one.one/cdn-cgi/trace',
      'https://1.0.0.1/cdn-cgi/trace',
      'https://cloudflare-dns.com/cdn-cgi/trace',
      'https://cloudflare-eth.com/cdn-cgi/trace',
    ];
    
    for (final endpoint in traceEndpoints) {
      try {
        final response = await http.get(
          Uri.parse(endpoint),
        ).timeout(const Duration(seconds: 8));
        
        if (response.statusCode == 200) {
          final lines = response.body.split('\n');
          String? country;
          String? ip;
          
          for (final line in lines) {
            if (line.startsWith('loc=')) {
              country = line.substring(4).trim().toUpperCase();
            } else if (line.startsWith('ip=')) {
              ip = line.substring(3).trim();
            }
          }
          
          if (country != null && ip != null) {
            _detectedCountryCode = country;
            _detectedIP = ip;
            debugPrint('Detected from trace: Country=$_detectedCountryCode, IP=$_detectedIP from $endpoint');
            notifyListeners();
            return _detectedCountryCode;
          }
        }
      } catch (e) {
        debugPrint('Cloudflare trace failed ($endpoint): $e');
        await Future.delayed(const Duration(milliseconds: 300));
        continue;
      }
    }
    
    debugPrint('All country detection endpoints failed');
    return null;
  }

  Future<bool> connect(V2RayConfig config, {AppSettings? settings}) async {
    final logger = LogService();
    try {
      logger.log('=== V2Ray Connection Start ===', level: LogLevel.info);
      logger.log('Config: ${config.remark}', level: LogLevel.info);
      logger.log('Address: ${config.address}:${config.port}', level: LogLevel.info);
      logger.log('Protocol: ${config.configType}', level: LogLevel.info);
      
      await initialize();
      logger.log('V2Ray initialized', level: LogLevel.info);

      final prefs = await SharedPreferences.getInstance();
      
      AppSettings appSettings;
      if (settings != null) {
        appSettings = settings;
      } else {
        final settingsJson = prefs.getString('app_settings');
        if (settingsJson != null) {
          appSettings = AppSettings.fromJson(jsonDecode(settingsJson));
        } else {
          appSettings = AppSettings();
        }
      }
      
      logger.log('App Settings loaded: proxyOnly=${appSettings.proxyOnlyMode}, mux=${appSettings.muxSettings.enabled}', level: LogLevel.info);

      final blockedAppsList = prefs.getStringList('blocked_apps');
      logger.log('Blocked apps count: ${blockedAppsList?.length ?? 0}', level: LogLevel.info);

      logger.log('Building full config...', level: LogLevel.info);
      final fullConfig = V2RayConfigBuilder.buildFullConfig(
        serverConfig: config,
        settings: appSettings,
        blockedApps: blockedAppsList,
      );

      final configJson = jsonEncode(fullConfig);
      logger.log('Config JSON generated: ${configJson.length} bytes', level: LogLevel.info);

      logger.log('Requesting VPN permission...', level: LogLevel.info);
      bool hasPermission = await _flutterV2ray.requestPermission();
      if (!hasPermission) {
        logger.log('VPN permission denied', level: LogLevel.error);
        return false;
      }
      logger.log('VPN permission granted', level: LogLevel.info);

      logger.log('Starting V2Ray core...', level: LogLevel.info);
      await _flutterV2ray.startV2Ray(
        remark: config.remark,
        config: configJson,
        blockedApps: blockedAppsList,
        proxyOnly: appSettings.proxyOnlyMode,
        notificationDisconnectButtonName: "DISCONNECT",
      );
      logger.log('V2Ray core start command sent', level: LogLevel.info);

      _activeConfig = config;
      await _saveActiveConfig(config);
      
      logger.log('Detecting country...', level: LogLevel.info);
      detectRealCountry();
      
      notifyListeners();

      logger.log('=== V2Ray Connection Success ===', level: LogLevel.info);
      return true;
    } catch (e, stackTrace) {
      logger.log('=== V2Ray Connection Error ===', level: LogLevel.error);
      logger.log('Error: $e', level: LogLevel.error);
      logger.log('Stack trace: $stackTrace', level: LogLevel.error);
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _flutterV2ray.stopV2Ray();
      _activeConfig = null;
      _detectedCountryCode = null;
      _detectedIP = null;
      _detectedCity = null;
      _detectedRegion = null;
      await _clearActiveConfig();
      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting from V2Ray: $e');
    }
  }

  Future<int?> getServerDelay(V2RayConfig config) async {
    final configId = config.id;
    final hostKey = '${config.address}:${config.port}';

    try {
      if (_pingCache.containsKey(hostKey)) {
        final cachedValue = _pingCache[hostKey];
        if (cachedValue != null) {
          return cachedValue;
        }
      }

      if (_pingInProgress[hostKey] == true) {
        int attempts = 0;
        while (_pingInProgress[hostKey] == true && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }
        return _pingCache[hostKey];
      }

      _pingInProgress[hostKey] = true;

      try {
        await initialize();
        
        final prefs = await SharedPreferences.getInstance();
        final settingsJson = prefs.getString('app_settings');
        AppSettings appSettings;
        if (settingsJson != null) {
          appSettings = AppSettings.fromJson(jsonDecode(settingsJson));
        } else {
          appSettings = AppSettings();
        }

        final fullConfig = V2RayConfigBuilder.buildFullConfig(
          serverConfig: config,
          settings: appSettings,
        );

        final configJson = jsonEncode(fullConfig);
        
        final delay = await _flutterV2ray
            .getServerDelay(config: configJson)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => -1,
            );

        if (delay >= 0 && delay < 10000) {
          _pingCache[hostKey] = delay;
          _pingCache[configId] = delay;
          _savePingCache();
        } else {
          _pingCache[hostKey] = -1;
          _pingCache[configId] = -1;
        }
        
        _pingInProgress[hostKey] = false;
        return delay >= 0 ? delay : null;
      } catch (e) {
        _pingInProgress[hostKey] = false;
        _pingCache[hostKey] = -1;
        return null;
      }
    } catch (e) {
      _pingInProgress[hostKey] = false;
      return null;
    }
  }

  void clearPingCache({String? configId}) {
    if (configId != null) {
      _pingCache.remove(configId);
    } else {
      _pingCache.clear();
    }
    _savePingCache();
  }

  Future<List<V2RayConfig>> parseSubscriptionUrl(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception('Network timeout: Check your internet connection');
            },
          );

      if (response.statusCode != 200) {
        throw Exception('Failed to load subscription: HTTP ${response.statusCode}');
      }

      return _parseContent(response.body, source: 'subscription');
    } catch (e) {
      debugPrint('Error parsing subscription: $e');
      
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception('Network error: Check your internet connection');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Connection timeout: Server is not responding');
      } else if (e.toString().contains('Invalid URL')) {
        throw Exception('Invalid subscription URL format');
      } else if (e.toString().contains('No valid configurations')) {
        throw Exception('No valid servers found in subscription');
      } else {
        throw Exception('Failed to update subscription: ${e.toString()}');
      }
    }
  }

  Future<List<V2RayConfig>> parseSubscriptionContent(String content) async {
    try {
      return _parseContent(content, source: 'subscription');
    } catch (e) {
      debugPrint('Error parsing subscription content: $e');
      
      if (e.toString().contains('No valid configurations')) {
        throw Exception('No valid servers found in file');
      } else {
        throw Exception('Failed to parse subscription file: ${e.toString()}');
      }
    }
  }

  Future<V2RayConfig?> parseConfigFromClipboard(String clipboardText) async {
    try {
      final configs = _parseContent(clipboardText, source: 'manual');
      if (configs.isNotEmpty) {
        final allConfigs = await loadConfigs();
        allConfigs.add(configs.first);
        await saveConfigs(allConfigs);
        return configs.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing clipboard config: $e');
      throw Exception('Invalid config format');
    }
  }

  List<V2RayConfig> _parseContent(String content, {String source = 'subscription'}) {
    final List<V2RayConfig> configs = [];

    try {
      if (_isBase64(content)) {
        final decoded = utf8.decode(base64.decode(content.trim()));
        content = decoded;
      }
    } catch (e) {
      debugPrint('Not a valid base64 content, using original: $e');
    }

    final List<String> lines = content.split('\n');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      try {
        if (line.startsWith('vmess://') ||
            line.startsWith('vless://') ||
            line.startsWith('trojan://') ||
            line.startsWith('ss://') ||
            line.startsWith('hysteria2://') ||
            line.startsWith('hy2://') ||
            line.startsWith('wireguard://') ||
            line.startsWith('wg://')) {
          V2RayURL parser = V2ray.parseFromURL(line);
          String configType = '';

          if (line.startsWith('vmess://')) {
            configType = 'vmess';
          } else if (line.startsWith('vless://')) {
            configType = 'vless';
          } else if (line.startsWith('ss://')) {
            configType = 'shadowsocks';
          } else if (line.startsWith('trojan://')) {
            configType = 'trojan';
          } else if (line.startsWith('hysteria2://') || line.startsWith('hy2://')) {
            configType = 'hysteria2';
          } else if (line.startsWith('wireguard://') || line.startsWith('wg://')) {
            configType = 'wireguard';
          }

          String address = parser.address;
          int port = parser.port;

          configs.add(
            V2RayConfig(
              id: DateTime.now().millisecondsSinceEpoch.toString() + configs.length.toString(),
              remark: parser.remark,
              address: address,
              port: port,
              configType: configType,
              fullConfig: line,
              source: source,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error parsing config: $e');
      }
    }

    if (configs.isEmpty) {
      throw Exception('No valid configurations found in subscription');
    }

    return configs;
  }

  bool _isBase64(String str) {
    str = str.trim();
    if (str.length % 4 != 0) {
      return false;
    }
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');
    return base64Pattern.hasMatch(str);
  }

  Future<void> saveConfigs(List<V2RayConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> configsJson = configs
        .map((config) => jsonEncode(config.toJson()))
        .toList();
    await prefs.setStringList('v2ray_configs', configsJson);
    notifyListeners();
  }

  Future<List<V2RayConfig>> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? configsJson = prefs.getStringList('v2ray_configs');
    if (configsJson == null) return [];

    return configsJson
        .map((json) => V2RayConfig.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> subscriptionsJson = subscriptions
        .map((sub) => jsonEncode(sub.toJson()))
        .toList();
    await prefs.setStringList('v2ray_subscriptions', subscriptionsJson);
  }

  Future<List<Subscription>> loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? subscriptionsJson = prefs.getStringList('v2ray_subscriptions');
    if (subscriptionsJson == null) return [];

    return subscriptionsJson
        .map((json) => Subscription.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> _saveActiveConfig(V2RayConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_config', jsonEncode(config.toJson()));
  }

  Future<void> _clearActiveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_config');
  }

  Future<V2RayConfig?> _loadActiveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final String? configJson = prefs.getString('active_config');
    if (configJson == null) return null;
    return V2RayConfig.fromJson(jsonDecode(configJson));
  }

  Future<void> saveSelectedConfig(V2RayConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_config', jsonEncode(config.toJson()));
    notifyListeners();
  }

  Future<V2RayConfig?> loadSelectedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final String? configJson = prefs.getString('selected_config');
    if (configJson == null) return null;
    return V2RayConfig.fromJson(jsonDecode(configJson));
  }

  Future<int?> getConnectedServerDelay() async {
    try {
      if (!isConnected || _activeConfig == null) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('app_settings');
      String testUrl = 'https://www.gstatic.com/generate_204';
      
      if (settingsJson != null) {
        try {
          final settings = AppSettings.fromJson(jsonDecode(settingsJson));
          testUrl = settings.connectionTestUrl;
        } catch (e) {
          debugPrint('Error loading test URL from settings: $e');
        }
      }

      final delay = await _flutterV2ray.getConnectedServerDelay(url: testUrl);
      if (delay >= 0) {
        return delay;
      }

      debugPrint('V2Ray delay failed, trying native ping...');
      final pingResult = await NativePingService.pingHost(
        host: _activeConfig!.address,
        port: _activeConfig!.port,
        timeoutMs: 5000,
        useCache: false,
      );

      if (pingResult.success) {
        return pingResult.latency;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting connected server delay: $e');
      
      if (_activeConfig != null) {
        try {
          final pingResult = await NativePingService.pingHost(
            host: _activeConfig!.address,
            port: _activeConfig!.port,
            timeoutMs: 5000,
            useCache: false,
          );

          if (pingResult.success) {
            return pingResult.latency;
          }
        } catch (pingError) {
          debugPrint('Native ping also failed: $pingError');
        }
      }
      
      return null;
    }
  }

  int? getCachedPing(String configId) {
    return _pingCache[configId];
  }

  Future<void> _tryRestoreActiveConfig() async {
    try {
      final delay = await _flutterV2ray.getConnectedServerDelay();
      final isConnected = delay >= 0;

      if (isConnected) {
        final savedConfig = await _loadActiveConfig();
        if (savedConfig != null) {
          _activeConfig = savedConfig;
          debugPrint('Restored active config: ${savedConfig.remark}');
          notifyListeners();
        }
      } else {
        await _clearActiveConfig();
        _activeConfig = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error restoring active config: $e');
      await _clearActiveConfig();
      _activeConfig = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
