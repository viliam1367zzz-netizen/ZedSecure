import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:zedsecure/services/v2ray_service.dart';
import 'package:zedsecure/services/log_service.dart';
import 'package:zedsecure/models/v2ray_config.dart';
import 'package:zedsecure/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  V2RayConfig? _selectedConfig;
  int? _currentPing;
  bool _isConnecting = false;
  
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    final service = Provider.of<V2RayService>(context, listen: false);
    service.addListener(_onServiceChanged);
    _loadSelectedConfig();
  }

  Future<void> _loadSelectedConfig() async {
    final service = Provider.of<V2RayService>(context, listen: false);
    final config = await service.loadSelectedConfig();
    if (config != null && mounted) {
      setState(() {
        _selectedConfig = config;
      });
    }
  }

  void _onServiceChanged() {
    if (mounted) {
      _loadSelectedConfig(); // Reload selected config when service changes
      setState(() {});
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    final service = Provider.of<V2RayService>(context, listen: false);
    service.removeListener(_onServiceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<V2RayService>(
      builder: (context, v2rayService, child) {
        final isConnected = v2rayService.isConnected;
        final activeConfig = v2rayService.activeConfig;
        final status = v2rayService.currentStatus;
        
        return Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Animated Bubbles Background
                ..._buildBubbles(),
                
                // Main Content
                Column(
                  children: [
                    // Header
                    _buildHeader(),
                    
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              
                              // Connection Status Card
                              _buildConnectionCard(isConnected, status),
                              
                              const SizedBox(height: 25),
                              
                              // Connect Button
                              _buildConnectButton(v2rayService, isConnected),
                              
                              const SizedBox(height: 25),
                              
                              // Active Server Card
                              if (_selectedConfig != null || activeConfig != null)
                                _buildServerCard(activeConfig ?? _selectedConfig!, isConnected),
                              
                              const SizedBox(height: 20),
                              
                              // Stats Grid
                              if (isConnected && status != null)
                                _buildStatsGrid(status),
                              
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Animated Bubbles
  List<Widget> _buildBubbles() {
    return List.generate(5, (index) {
      final random = math.Random(index);
      final size = 15.0 + random.nextDouble() * 20;
      final left = random.nextDouble() * MediaQuery.of(context).size.width;
      final delay = index * 2.0;
      
      return AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          final progress = ((_waveController.value * 2 + delay / 10) % 1.0);
          final bottom = -50 + (MediaQuery.of(context).size.height + 100) * progress;
          final opacity = progress < 0.1 ? progress * 4 : (progress > 0.9 ? (1 - progress) * 4 : 0.4);
          
          return Positioned(
            left: left,
            bottom: bottom,
            child: Opacity(
              opacity: opacity.clamp(0.0, 0.4),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.oceanBlue.withOpacity(0.1),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  // Header
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: AppTheme.oceanButtonDecoration(
                  borderRadius: 14,
                  isActive: true,
                ),
                child: const Center(
                  child: Text('🌊', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  style: AppTheme.oceanTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  children: const [
                    TextSpan(text: 'Zed'),
                    TextSpan(
                      text: 'Secure',
                      style: TextStyle(color: AppTheme.oceanBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Settings Button
          GestureDetector(
            onTap: () => _showLogsModal(),
            child: Container(
              width: 42,
              height: 42,
              decoration: AppTheme.glassDecoration(borderRadius: 12),
              child: const Icon(
                CupertinoIcons.doc_text,
                color: AppTheme.oceanBlue,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Connection Card with Wave
  Widget _buildConnectionCard(bool isConnected, dynamic status) {
    final statusColor = isConnected ? AppTheme.connectedGreen : AppTheme.oceanBlue;
    final duration = status?.duration ?? '00:00:00';
    final uploadSpeed = AppTheme.formatSpeed(status?.uploadSpeed);
    final downloadSpeed = AppTheme.formatSpeed(status?.downloadSpeed);
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: AppTheme.cardGradient,
            border: Border.all(
              color: statusColor.withOpacity(0.3 + _pulseController.value * 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.15 + _pulseController.value * 0.1),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // Status Row
              Row(
                children: [
                  // Status Indicator
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      isConnected ? CupertinoIcons.lock_shield_fill : CupertinoIcons.shield,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Status Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected ? 'Protected' : 'Not Protected',
                          style: AppTheme.oceanTextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withOpacity(0.8),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isConnected ? 'Connected • $duration' : 'Tap to connect',
                              style: AppTheme.oceanTextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Speed Row (only when connected)
              if (isConnected) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildSpeedItem(
                      icon: CupertinoIcons.arrow_up,
                      label: 'Upload',
                      value: uploadSpeed,
                      color: AppTheme.connectedGreen,
                    ),
                    const SizedBox(width: 12),
                    _buildSpeedItem(
                      icon: CupertinoIcons.arrow_down,
                      label: 'Download',
                      value: downloadSpeed,
                      color: AppTheme.oceanBlue,
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeedItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withOpacity(0.3),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: color.withOpacity(0.2),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.oceanTextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTheme.oceanTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Connect Button with Orbiting Particles
  Widget _buildConnectButton(V2RayService service, bool isConnected) {
    final color = isConnected ? AppTheme.connectedGreen : AppTheme.oceanBlue;
    
    return GestureDetector(
      onTap: _isConnecting ? null : () => _toggleConnection(service),
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Orbit Rings
            ...List.generate(2, (index) {
              final size = 180.0 + (index * 40);
              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withOpacity(0.2 + _pulseController.value * 0.1),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                  );
                },
              );
            }),
            
            // Orbiting Particles
            AnimatedBuilder(
              animation: _orbitController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _orbitController.value * 2 * math.pi,
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 95,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.connectedGreen,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.connectedGreen.withOpacity(0.8),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 95,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.oceanBlue,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.oceanBlue.withOpacity(0.8),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Main Button
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.darkCard,
                    border: Border.all(
                      color: color.withOpacity(0.5 + _pulseController.value * 0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3 + _pulseController.value * 0.2),
                        blurRadius: 40,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isConnecting)
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            color: color,
                            strokeWidth: 3,
                          ),
                        )
                      else
                        Icon(
                          isConnected ? CupertinoIcons.power : CupertinoIcons.bolt_fill,
                          color: color,
                          size: 45,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        _isConnecting 
                            ? 'Connecting...' 
                            : (isConnected ? 'Disconnect' : 'Connect'),
                        style: AppTheme.oceanTextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          withGlow: true,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Server Card
  Widget _buildServerCard(V2RayConfig config, bool isConnected) {
    final countryCode = config.countryCode ?? 'UN';
    final flagEmoji = _getCountryEmoji(countryCode);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'ACTIVE SERVER',
            style: AppTheme.oceanTextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.oceanGlowDecoration(
            color: isConnected ? AppTheme.connectedGreen : AppTheme.oceanBlue,
            borderRadius: 20,
            glowIntensity: isConnected ? 0.25 : 0.15,
          ),
          child: Row(
            children: [
              // Flag
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: AppTheme.cardGradient,
                  border: Border.all(
                    color: AppTheme.oceanBlue.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(flagEmoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              
              // Server Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.remark,
                      style: AppTheme.oceanTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: AppTheme.connectedGreen.withOpacity(0.2),
                          ),
                          child: Text(
                            config.configType.toUpperCase(),
                            style: AppTheme.oceanTextStyle(
                              color: AppTheme.connectedGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          config.address,
                          style: AppTheme.oceanTextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Ping
              if (_currentPing != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_currentPing}ms',
                      style: AppTheme.oceanTextStyle(
                        color: AppTheme.getPingColor(_currentPing),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'PING',
                      style: AppTheme.oceanTextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Stats Grid
  Widget _buildStatsGrid(dynamic status) {
    return Row(
      children: [
        _buildStatCard(
          icon: CupertinoIcons.arrow_up_circle_fill,
          label: 'Uploaded',
          value: AppTheme.formatBytes(status.upload),
          color: AppTheme.connectedGreen,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: CupertinoIcons.arrow_down_circle_fill,
          label: 'Downloaded',
          value: AppTheme.formatBytes(status.download),
          color: AppTheme.oceanBlue,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: CupertinoIcons.clock_fill,
          label: 'Uptime',
          value: '99%',
          color: AppTheme.oceanCyan,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: AppTheme.glassDecoration(borderRadius: 18),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTheme.oceanTextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.oceanTextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Toggle Connection
  Future<void> _toggleConnection(V2RayService service) async {
    if (_isConnecting) return;
    
    setState(() => _isConnecting = true);
    
    try {
      if (service.isConnected) {
        await service.disconnect();
        _currentPing = null;
      } else {
        if (_selectedConfig == null) {
          _showNoServerDialog();
          return;
        }
        await service.connect(_selectedConfig!);
        _startPingMonitor(service);
      }
    } catch (e) {
      debugPrint('Connection error: $e');
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  void _startPingMonitor(V2RayService service) async {
    while (mounted && service.isConnected) {
      final ping = await service.getConnectedServerDelay();
      if (mounted) {
        setState(() => _currentPing = ping);
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  void _showNoServerDialog() {
    setState(() => _isConnecting = false);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('No Server Selected'),
        content: const Text('Please select a server from the Servers tab first.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String _getCountryEmoji(String countryCode) {
    final Map<String, String> flags = {
      'US': '🇺🇸', 'DE': '🇩🇪', 'NL': '🇳🇱', 'FR': '🇫🇷', 'GB': '🇬🇧',
      'JP': '🇯🇵', 'SG': '🇸🇬', 'HK': '🇭🇰', 'KR': '🇰🇷', 'CA': '🇨🇦',
      'AU': '🇦🇺', 'FI': '🇫🇮', 'SE': '🇸🇪', 'CH': '🇨🇭', 'IR': '🇮🇷',
      'TR': '🇹🇷', 'RU': '🇷🇺', 'IN': '🇮🇳', 'BR': '🇧🇷', 'AE': '🇦🇪',
    };
    return flags[countryCode.toUpperCase()] ?? '🌍';
  }

  // Logs Modal
  void _showLogsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: AppTheme.textMuted,
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.doc_text, color: AppTheme.oceanBlue),
                  const SizedBox(width: 12),
                  Text(
                    'Connection Logs',
                    style: AppTheme.oceanTextStyle(
                      color: AppTheme.oceanBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      LogService().clear();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: AppTheme.disconnectedRed.withOpacity(0.2),
                        border: Border.all(color: AppTheme.disconnectedRed.withOpacity(0.5)),
                      ),
                      child: Text(
                        'Clear',
                        style: AppTheme.oceanTextStyle(
                          color: AppTheme.disconnectedRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Logs List
            Expanded(
              child: ListenableBuilder(
                listenable: LogService(),
                builder: (context, child) {
                  final logs = LogService().logs;
                  if (logs.isEmpty) {
                    return Center(
                      child: Text(
                        'No logs yet',
                        style: AppTheme.oceanTextStyle(color: AppTheme.textMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      Color levelColor;
                      switch (log.level) {
                        case LogLevel.info:
                          levelColor = AppTheme.oceanBlue;
                          break;
                        case LogLevel.warning:
                          levelColor = AppTheme.warningOrange;
                          break;
                        case LogLevel.error:
                          levelColor = AppTheme.disconnectedRed;
                          break;
                        case LogLevel.debug:
                          levelColor = AppTheme.connectedGreen;
                          break;
                        default:
                          levelColor = AppTheme.systemGray;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: levelColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                log.toString(),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
