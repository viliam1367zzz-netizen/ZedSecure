import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zedsecure/services/v2ray_service.dart';
import 'package:zedsecure/services/country_detector.dart';
import 'package:zedsecure/services/log_service.dart';
import 'package:zedsecure/models/v2ray_config.dart';
import 'package:zedsecure/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isConnecting = false;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  V2RayConfig? _selectedConfig;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _loadSelectedConfig();
    final service = Provider.of<V2RayService>(context, listen: false);
    service.addListener(_onServiceChanged);
  }

  void _onServiceChanged() {
    _loadSelectedConfig();
  }

  Future<void> _loadSelectedConfig() async {
    final service = Provider.of<V2RayService>(context, listen: false);
    final config = await service.loadSelectedConfig();
    if (mounted) {
      setState(() => _selectedConfig = config);
    }
  }

  @override
  void dispose() {
    final service = Provider.of<V2RayService>(context, listen: false);
    service.removeListener(_onServiceChanged);
    _rotationController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<V2RayService>(
      builder: (context, v2rayService, child) {
        final isConnected = v2rayService.isConnected;
        final activeConfig = v2rayService.activeConfig;
        final status = v2rayService.currentStatus;
        final displayConfig = activeConfig ?? _selectedConfig;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkBg,
                AppTheme.darkBg2,
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (isConnected && status != null)
                  _buildDynamicIsland(v2rayService, status),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // App Title with Neon Effect
                      Text(
                        'ZED SECURE',
                        style: AppTheme.neonTextStyle(
                          color: AppTheme.neonCyan,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showLogViewer(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: AppTheme.neonButtonDecoration(
                            color: AppTheme.neonCyan,
                            borderRadius: 20,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.doc_text,
                                size: 16,
                                color: AppTheme.neonCyan,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Logs',
                                style: AppTheme.neonTextStyle(
                                  color: AppTheme.neonCyan,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildConnectionWidget(isConnected, v2rayService),
                        const SizedBox(height: 40),
                        if (displayConfig != null)
                          _buildServerCard(displayConfig, v2rayService, isConnected)
                        else
                          _buildNoServerCard(),
                        const SizedBox(height: 20),
                        if (isConnected && status != null)
                          _buildStatsGrid(status),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDynamicIsland(V2RayService service, dynamic status) {
    final duration = status.duration ?? '00:00:00';
    final uploadSpeed = AppTheme.formatSpeed(status.uploadSpeed);
    final downloadSpeed = AppTheme.formatSpeed(status.downloadSpeed);
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: AppTheme.darkCard,
            border: Border.all(
              color: AppTheme.neonGreen.withOpacity(0.5 + (_pulseController.value * 0.3)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonGreen.withOpacity(0.3 + (_pulseController.value * 0.2)),
                blurRadius: 20 + (_pulseController.value * 10),
                spreadRadius: 2 + (_pulseController.value * 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Animated Neon Dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonGreen,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonGreen.withOpacity(0.8),
                      blurRadius: 10 + (_pulseController.value * 5),
                      spreadRadius: 2 + (_pulseController.value * 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CONNECTED',
                      style: AppTheme.neonTextStyle(
                        color: AppTheme.neonGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.neonGreen.withOpacity(0.15),
                  border: Border.all(
                    color: AppTheme.neonGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_up,
                      size: 12,
                      color: AppTheme.neonGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      uploadSpeed,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.neonGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.arrow_down,
                      size: 12,
                      color: AppTheme.neonCyan,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      downloadSpeed,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.neonCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionWidget(bool isConnected, V2RayService service) {
    final color = isConnected ? AppTheme.neonGreen : AppTheme.neonCyan;
    
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => _toggleConnection(service),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow Ring
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2 + (_glowController.value * 0.1)),
                      blurRadius: 50 + (_glowController.value * 20),
                      spreadRadius: 10 + (_glowController.value * 5),
                    ),
                  ],
                ),
              ),
              // Rotating Ring
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: CustomPaint(
                      size: const Size(200, 200),
                      painter: _NeonRingPainter(
                        isConnected: isConnected,
                        progress: _isConnecting ? 0.3 : 1.0,
                        glowIntensity: _glowController.value,
                      ),
                    ),
                  );
                },
              ),
              // Center Button
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.darkCard,
                  border: Border.all(
                    color: color.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isConnected ? CupertinoIcons.power : CupertinoIcons.bolt_fill,
                      size: 50,
                      color: color,
                      shadows: [
                        Shadow(
                          color: color.withOpacity(0.8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isConnecting 
                          ? 'CONNECTING...'
                          : (isConnected ? 'DISCONNECT' : 'CONNECT'),
                      style: AppTheme.neonTextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServerCard(V2RayConfig config, V2RayService service, bool isConnected) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.neonGlowDecoration(
        glowColor: isConnected ? AppTheme.neonGreen : AppTheme.neonCyan,
        borderRadius: 20,
        glowIntensity: 0.3,
        glowBlur: 15,
        glowSpread: 5,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Server Icon with Neon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.neonCyan.withOpacity(0.3),
                      AppTheme.neonPurple.withOpacity(0.3),
                    ],
                  ),
                  border: Border.all(
                    color: AppTheme.neonCyan.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.globe,
                  color: AppTheme.neonCyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.remark,
                      style: AppTheme.neonTextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${config.configType.toUpperCase()} • ${config.address}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.systemGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: (isConnected ? AppTheme.neonGreen : AppTheme.neonCyan).withOpacity(0.15),
                  border: Border.all(
                    color: (isConnected ? AppTheme.neonGreen : AppTheme.neonCyan).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  isConnected ? 'ACTIVE' : 'SELECTED',
                  style: AppTheme.neonTextStyle(
                    color: isConnected ? AppTheme.neonGreen : AppTheme.neonCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (isConnected) ...[
            const SizedBox(height: 16),
            _PingCardWidget(service: service),
          ],
        ],
      ),
    );
  }

  Widget _buildNoServerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: AppTheme.neonGlowDecoration(
        glowColor: AppTheme.neonPurple,
        borderRadius: 20,
        glowIntensity: 0.2,
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.antenna_radiowaves_left_right,
            size: 50,
            color: AppTheme.neonPurple,
          ),
          const SizedBox(height: 16),
          Text(
            'NO SERVER SELECTED',
            style: AppTheme.neonTextStyle(
              color: AppTheme.neonPurple,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to Servers tab to add or select a server',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic status) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: CupertinoIcons.arrow_up_circle_fill,
                title: 'UPLOAD',
                value: AppTheme.formatBytes(status.upload),
                color: AppTheme.neonGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: CupertinoIcons.arrow_down_circle_fill,
                title: 'DOWNLOAD',
                value: AppTheme.formatBytes(status.download),
                color: AppTheme.neonCyan,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.neonGlowDecoration(
        glowColor: color,
        borderRadius: 16,
        glowIntensity: 0.2,
        glowBlur: 10,
        glowSpread: 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white60,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.neonTextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleConnection(V2RayService service) async {
    if (_isConnecting) return;

    if (service.isConnected) {
      await service.disconnect();
    } else {
      if (_selectedConfig == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a server first'),
            backgroundColor: AppTheme.disconnectedRed,
          ),
        );
        return;
      }

      setState(() => _isConnecting = true);
      
      try {
        await service.connect(_selectedConfig!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection failed: $e'),
              backgroundColor: AppTheme.disconnectedRed,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isConnecting = false);
        }
      }
    }
  }

  void _showLogViewer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: AppTheme.neonCyan.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonCyan.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppTheme.neonCyan.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'LOGS',
                    style: AppTheme.neonTextStyle(
                      color: AppTheme.neonCyan,
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
                      decoration: AppTheme.neonButtonDecoration(
                        color: AppTheme.disconnectedRed,
                        borderRadius: 15,
                      ),
                      child: Text(
                        'Clear',
                        style: TextStyle(
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
            Expanded(
              child: ListenableBuilder(
                listenable: LogService(),
                builder: (context, child) {
                  final logs = LogService().logs;
                  if (logs.isEmpty) {
                    return Center(
                      child: Text(
                        'No logs yet',
                        style: TextStyle(color: Colors.white60),
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
                          levelColor = AppTheme.neonCyan;
                          break;
                        case LogLevel.warning:
                          levelColor = AppTheme.neonOrange;
                          break;
                        case LogLevel.error:
                          levelColor = AppTheme.disconnectedRed;
                          break;
                        case LogLevel.debug:
                          levelColor = AppTheme.neonGreen;
                          break;
                        default:
                          levelColor = AppTheme.systemGray;
                          break;
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
                                boxShadow: [
                                  BoxShadow(
                                    color: levelColor.withOpacity(0.5),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableText(
                                log.toString(),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Colors.white70,
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

class _PingCardWidget extends StatefulWidget {
  final V2RayService service;

  const _PingCardWidget({required this.service});

  @override
  State<_PingCardWidget> createState() => _PingCardWidgetState();
}

class _PingCardWidgetState extends State<_PingCardWidget> {
  int? _ping;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPing();
  }

  Future<void> _loadPing() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final ping = await widget.service.getConnectedServerDelay();
      if (mounted) {
        setState(() {
          _ping = ping;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ping = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pingColor = AppTheme.getPingColor(_ping);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: pingColor.withOpacity(0.1),
        border: Border.all(
          color: pingColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.speedometer,
            size: 20,
            color: pingColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LATENCY',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white60,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  _isLoading 
                      ? 'Testing...' 
                      : (_ping != null && _ping! >= 0 ? '${_ping}ms' : 'N/A'),
                  style: AppTheme.neonTextStyle(
                    color: pingColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isLoading ? null : _loadPing,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppTheme.neonCyan.withOpacity(0.1),
                border: Border.all(
                  color: AppTheme.neonCyan.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.neonCyan,
                      ),
                    )
                  : Icon(
                      CupertinoIcons.refresh,
                      size: 18,
                      color: AppTheme.neonCyan,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonRingPainter extends CustomPainter {
  final bool isConnected;
  final double progress;
  final double glowIntensity;

  _NeonRingPainter({
    required this.isConnected,
    required this.progress,
    this.glowIntensity = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final color = isConnected ? AppTheme.neonGreen : AppTheme.neonCyan;
    
    // Background ring
    final bgPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Main neon ring with gradient
    final fgPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.1),
          color.withOpacity(0.5),
          color,
          color.withOpacity(0.5),
          color.withOpacity(0.1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
    
    // Glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3 + (glowIntensity * 0.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NeonRingPainter oldDelegate) {
    return oldDelegate.isConnected != isConnected || 
           oldDelegate.progress != progress ||
           oldDelegate.glowIntensity != glowIntensity;
  }
}
