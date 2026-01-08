import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zedsecure/services/v2ray_service.dart';
import 'package:zedsecure/services/theme_service.dart';
import 'package:zedsecure/models/v2ray_config.dart';
import 'package:zedsecure/theme/app_theme.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ServersScreen extends StatefulWidget {
  const ServersScreen({super.key});

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  List<V2RayConfig> _configs = [];
  bool _isLoading = true;
  bool _isSorting = false;
  String _searchQuery = '';
  final Map<String, int?> _pingResults = {};
  String? _selectedConfigId;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
    _loadSelectedConfig();
    final service = Provider.of<V2RayService>(context, listen: false);
    service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    final service = Provider.of<V2RayService>(context, listen: false);
    service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    _loadConfigs();
  }

  Future<void> _loadSelectedConfig() async {
    final service = Provider.of<V2RayService>(context, listen: false);
    final selected = await service.loadSelectedConfig();
    if (selected != null) {
      setState(() => _selectedConfigId = selected.id);
    }
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    final service = Provider.of<V2RayService>(context, listen: false);
    final configs = await service.loadConfigs();
    setState(() {
      _configs = configs;
      _isLoading = false;
    });
  }

  Future<void> _pingAllServers() async {
    setState(() {
      _isSorting = true;
      _pingResults.clear();
    });

    final service = Provider.of<V2RayService>(context, listen: false);
    final futures = <Future>[];
    
    for (int i = 0; i < _configs.length; i++) {
      final config = _configs[i];
      final future = service.getServerDelay(config).then((ping) {
        if (mounted) setState(() => _pingResults[config.id] = ping ?? -1);
      }).catchError((e) {
        if (mounted) setState(() => _pingResults[config.id] = -1);
      });
      futures.add(future);
      if (futures.length >= 30 || i == _configs.length - 1) {
        await Future.wait(futures);
        futures.clear();
      }
    }

    if (mounted) {
      _sortByPing();
      setState(() => _isSorting = false);
    }
  }

  void _sortByPing() {
    setState(() {
      _configs.sort((a, b) {
        final pingA = _pingResults[a.id] ?? 999999;
        final pingB = _pingResults[b.id] ?? 999999;
        if (pingA == -1 && pingB == -1) return 0;
        if (pingA == -1) return 1;
        if (pingB == -1) return -1;
        return pingA.compareTo(pingB);
      });
    });
  }

  List<V2RayConfig> get _filteredConfigs {
    if (_searchQuery.isEmpty) return _configs;
    return _configs.where((config) {
      return config.remark.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          config.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          config.configType.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<V2RayConfig> get _manualConfigs => _filteredConfigs.where((c) => c.source == 'manual').toList();
  List<V2RayConfig> get _subscriptionConfigs => _filteredConfigs.where((c) => c.source == 'subscription').toList();

  Future<void> _importFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData == null || clipboardData.text == null || clipboardData.text!.isEmpty) {
        _showSnackBar('Empty Clipboard', 'Please copy a config first');
        return;
      }
      final service = Provider.of<V2RayService>(context, listen: false);
      final config = await service.parseConfigFromClipboard(clipboardData.text!);
      if (config != null) {
        await _loadConfigs();
        _showSnackBar('Config Added', '${config.remark} added successfully');
      }
    } catch (e) {
      _showSnackBar('Import Failed', e.toString());
    }
  }

  void _showSnackBar(String title, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message, style: const TextStyle(fontSize: 12)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1C1C1E), Colors.black]
              : [const Color(0xFFF2F2F7), Colors.white],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildSearchBar(isDark),
            Expanded(child: _buildServerList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Servers',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Row(
            children: [
              _buildIconButton(CupertinoIcons.doc_on_clipboard, _importFromClipboard, isDark),
              _buildIconButton(CupertinoIcons.qrcode_viewfinder, _scanQRCode, isDark),
              _isSorting
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CupertinoActivityIndicator(),
                    )
                  : _buildIconButton(CupertinoIcons.sort_down, _pingAllServers, isDark),
              _buildIconButton(CupertinoIcons.refresh, _loadConfigs, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 22,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: CupertinoSearchTextField(
        placeholder: 'Search servers...',
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildServerList(bool isDark) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }
    
    if (_filteredConfigs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.rectangle_stack, size: 64, color: AppTheme.systemGray),
            const SizedBox(height: 16),
            Text(
              'No servers found',
              style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              'Add servers from Subscriptions',
              style: TextStyle(fontSize: 14, color: AppTheme.systemGray),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        if (_manualConfigs.isNotEmpty) ...[
          _buildSectionHeader('Manual Configs', _manualConfigs.length, CupertinoIcons.pencil, isDark),
          ..._manualConfigs.map((c) => _buildServerCard(c, isDark)),
          const SizedBox(height: 24),
        ],
        if (_subscriptionConfigs.isNotEmpty) ...[
          _buildSectionHeader('Subscription Configs', _subscriptionConfigs.length, CupertinoIcons.cloud_download, isDark),
          ..._subscriptionConfigs.map((c) => _buildServerCard(c, isDark)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryBlue),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(V2RayConfig config, bool isDark) {
    final ping = _pingResults[config.id];
    final service = Provider.of<V2RayService>(context, listen: false);
    final isConnected = service.activeConfig?.id == config.id;
    final isSelected = _selectedConfigId == config.id;

    return GestureDetector(
      onTap: isConnected ? null : () => _handleSelectConfig(config),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          border: isSelected && !isConnected
              ? Border.all(color: AppTheme.primaryBlue, width: 2)
              : (isConnected ? Border.all(color: AppTheme.connectedGreen, width: 2) : null),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isConnected)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.connectedGreen,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          config.remark,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${config.address}:${config.port}',
                    style: TextStyle(fontSize: 12, color: AppTheme.systemGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                    ),
                    child: Text(
                      config.protocolDisplay,
                      style: TextStyle(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildPingBadge(ping),
            _buildActionButtons(config, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPingBadge(int? ping) {
    if (ping == null) return const SizedBox(width: 50);
    
    return Container(
      constraints: const BoxConstraints(minWidth: 50),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getPingColor(ping).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        ping >= 0 ? '${ping}ms' : 'Fail',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.getPingColor(ping),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButtons(V2RayConfig config, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _pingSingleServer(config),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(CupertinoIcons.speedometer, size: 20, color: AppTheme.primaryBlue),
          ),
        ),
        GestureDetector(
          onTap: () => _showOptionsSheet(config),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(CupertinoIcons.ellipsis, size: 20, color: AppTheme.systemGray),
          ),
        ),
      ],
    );
  }

  IconData _getProtocolIcon(String type) {
    switch (type.toLowerCase()) {
      case 'vmess': return CupertinoIcons.shield;
      case 'vless': return CupertinoIcons.shield_fill;
      case 'trojan': return CupertinoIcons.lock_shield;
      case 'shadowsocks': return CupertinoIcons.lock_fill;
      default: return CupertinoIcons.rectangle_stack;
    }
  }

  void _showOptionsSheet(V2RayConfig config) {
    final service = Provider.of<V2RayService>(context, listen: false);
    final isConnected = service.activeConfig?.id == config.id;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(config.remark),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _handleConnect(config);
            },
            child: Text(isConnected ? 'Disconnect' : 'Connect'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _copyConfig(config);
            },
            child: const Text('Copy Config'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showQRCode(config);
            },
            child: const Text('Show QR Code'),
          ),
          if (!isConnected)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _deleteConfig(config);
              },
              child: const Text('Delete'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _handleSelectConfig(V2RayConfig config) async {
    setState(() => _selectedConfigId = config.id);
    final service = Provider.of<V2RayService>(context, listen: false);
    await service.saveSelectedConfig(config);
    _showSnackBar('Server Selected', '${config.remark} is now selected');
  }

  Future<void> _pingSingleServer(V2RayConfig config) async {
    setState(() => _pingResults[config.id] = null);
    final service = Provider.of<V2RayService>(context, listen: false);
    final ping = await service.getServerDelay(config);
    if (mounted) setState(() => _pingResults[config.id] = ping ?? -1);
  }

  Future<void> _handleConnect(V2RayConfig config) async {
    final service = Provider.of<V2RayService>(context, listen: false);
    if (service.activeConfig?.id == config.id) {
      await service.disconnect();
      _showSnackBar('Disconnected', 'VPN disconnected');
    } else {
      if (service.isConnected) await service.disconnect();
      final success = await service.connect(config);
      _showSnackBar(
        success ? 'Connected' : 'Connection Failed',
        success ? 'Connected to ${config.remark}' : 'Failed to connect',
      );
    }
  }

  Future<void> _copyConfig(V2RayConfig config) async {
    await Clipboard.setData(ClipboardData(text: config.fullConfig));
    _showSnackBar('Config Copied', '${config.remark} copied to clipboard');
  }

  Future<void> _showQRCode(V2RayConfig config) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                config.remark,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: config.fullConfig,
                  version: QrVersions.auto,
                  size: 260,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan to import config',
                style: TextStyle(fontSize: 13, color: AppTheme.systemGray),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteConfig(V2RayConfig config) async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Config'),
        content: Text('Are you sure you want to delete "${config.remark}"?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              final service = Provider.of<V2RayService>(context, listen: false);
              final configs = await service.loadConfigs();
              configs.removeWhere((c) => c.id == config.id);
              await service.saveConfigs(configs);
              service.clearPingCache(configId: config.id);
              await _loadConfigs();
              _showSnackBar('Config Deleted', '${config.remark} has been deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanQRCode() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showSnackBar('Permission Denied', 'Camera permission is required');
      return;
    }

    if (mounted) {
      await Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => _QRScannerScreen(
            onQRScanned: (String code) async {
              Navigator.pop(context);
              try {
                final service = Provider.of<V2RayService>(context, listen: false);
                final config = await service.parseConfigFromClipboard(code);
                if (config != null) {
                  await _loadConfigs();
                  _showSnackBar('Config Added', '${config.remark} added from QR code');
                }
              } catch (e) {
                _showSnackBar('Invalid QR Code', e.toString());
              }
            },
          ),
        ),
      );
    }
  }
}

class _QRScannerScreen extends StatefulWidget {
  final Function(String) onQRScanned;
  const _QRScannerScreen({required this.onQRScanned});

  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (isScanning) {
      for (final barcode in capture.barcodes) {
        if (barcode.rawValue != null) {
          isScanning = false;
          controller.stop();
          widget.onQRScanned(barcode.rawValue!);
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Scan QR Code'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryBlue, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Position the QR code within the frame',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
