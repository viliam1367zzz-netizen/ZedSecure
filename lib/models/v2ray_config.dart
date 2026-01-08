import 'package:zedsecure/services/country_detector.dart';

class V2RayConfig {
  final String id;
  final String remark;
  final String address;
  final int port;
  final String configType;
  final String fullConfig;
  bool isConnected;
  final String source;
  final String? countryCode;

  V2RayConfig({
    required this.id,
    required this.remark,
    required this.address,
    required this.port,
    required this.configType,
    required this.fullConfig,
    this.isConnected = false,
    this.source = 'manual',
    String? countryCode,
  }) : countryCode = countryCode ?? CountryDetector.detectCountryCode(remark, address);

  factory V2RayConfig.fromJson(Map<String, dynamic> json) {
    return V2RayConfig(
      id: json['id'] as String,
      remark: json['remark'] as String,
      address: json['address'] as String,
      port: json['port'] as int,
      configType: json['configType'] as String,
      fullConfig: json['fullConfig'] as String,
      isConnected: json['isConnected'] as bool? ?? false,
      source: json['source'] as String? ?? 'manual',
      countryCode: json['countryCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'remark': remark,
      'address': address,
      'port': port,
      'configType': configType,
      'fullConfig': fullConfig,
      'isConnected': isConnected,
      'source': source,
      'countryCode': countryCode,
    };
  }

  V2RayConfig copyWith({
    String? id,
    String? remark,
    String? address,
    int? port,
    String? configType,
    String? fullConfig,
    bool? isConnected,
    String? source,
    String? countryCode,
  }) {
    return V2RayConfig(
      id: id ?? this.id,
      remark: remark ?? this.remark,
      address: address ?? this.address,
      port: port ?? this.port,
      configType: configType ?? this.configType,
      fullConfig: fullConfig ?? this.fullConfig,
      isConnected: isConnected ?? this.isConnected,
      source: source ?? this.source,
      countryCode: countryCode ?? this.countryCode,
    );
  }

  String get protocolDisplay {
    switch (configType.toLowerCase()) {
      case 'vmess':
        return 'VMess';
      case 'vless':
        return 'VLESS';
      case 'trojan':
        return 'Trojan';
      case 'shadowsocks':
        return 'Shadowsocks';
      default:
        return configType.toUpperCase();
    }
  }
}

