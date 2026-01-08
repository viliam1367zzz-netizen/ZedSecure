import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zedsecure/services/v2ray_service.dart';
import 'package:zedsecure/services/country_detector.dart';
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
  bool _isIslandExpanded = true;
  V2RayConfig? _selectedConfig;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
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
    super.dispose();
  }

  void _toggleIsland() {
    setState(() => _isIslandExpanded = !_isIslandExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
              colors: isDark
                  ? [const Color(0xFF1C1C1E), Colors.black]
                  : [const Color(0xFFF2F2F7), Colors.white],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildDynamicIsland(isConnected, status),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildConnectionWidget(isConnected, v2rayService, isDark),
                        const SizedBox(height: 40),
                        if (displayConfig != null)
                          _buildServerCard(displayConfig, v2rayService, isConnected, isDark)
                        else
                          _buildNoServerCard(isDark),
                        const SizedBox(height: 20),
                        if (isConnected && status != null)
                          _buildStatsGrid(status, isDark),
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

  Widget _buildDynamicIsland(bool isConnected, dynamic status) {
    return GestureDetector(
      onTap: _toggleIsland,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          width: _isIslandExpanded ? 200 : 120,
          height: _isIslandExpanded ? 44 : 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_isIslandExpanded ? 22 : 16),
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: isConnected 
                    ? AppTheme.connectedGreen.withOpacity(0.4)
                    : Colors.black.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_isIslandExpanded ? 22 : 16),
            child: _isIslandExpanded
                ? _buildExpandedIsland(isConnected, status)
                : _buildCollapsedIsland(isConnected),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedIsland(bool isConnected, dynamic status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? AppTheme.connectedGreen : AppTheme.disconnectedRed,
                  boxShadow: [
                    BoxShadow(
                      color: (isConnected ? AppTheme.connectedGreen : AppTheme.disconnectedRed).withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (isConnected && status != null)
            Text(
              status.duration,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsedIsland(bool isConnected) {
    return Center(
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isConnected ? AppTheme.connectedGreen : AppTheme.disconnectedRed,
        ),
      ),
    );
  }

  Widget _buildConnectionWidget(bool isConnected, V2RayService service, bool isDark) {
    return GestureDetector(
      onTap: _isConnecting ? null : () => _handleConnectionToggle(service),
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(200, 200),
                    painter: _RingPainter(
                      isConnected: isConnected,
                      progress: isConnected ? 1.0 : 0.3,
                    ),
                  ),
                );
              },
            ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: (isConnected ? AppTheme.connectedGreen : AppTheme.primaryBlue).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: _isConnecting
                    ? const CupertinoActivityIndicator(radius: 18)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isConnected ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.shield_fill,
                            size: 44,
                            color: isConnected ? AppTheme.connectedGreen : AppTheme.primaryBlue,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isConnected ? 'Protected' : 'Connect',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isConnected ? AppTheme.connectedGreen : AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoServerCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.globe, size: 48, color: AppTheme.systemGray),
          const SizedBox(height: 12),
          Text(
            'No Server Selected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Go to Servers tab to select one',
            style: TextStyle(fontSize: 13, color: AppTheme.systemGray),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagWidget(String countryCode) {
    final code = countryCode.toLowerCase();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SvgPicture.asset(
        'assets/flags/$code.svg',
        width: 48,
        height: 36,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => _buildFallbackFlag(countryCode),
      ),
    );
  }

  Widget _buildFallbackFlag(String countryCode) {
    return Container(
      width: 48,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          countryCode.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildServerCard(V2RayConfig config, V2RayService service, bool isConnected, bool isDark) {
    final countryCode = isConnected 
        ? (service.detectedCountryCode ?? CountryDetector.detectCountryCode(config.remark, config.address))
        : CountryDetector.detectCountryCode(config.remark, config.address);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: isConnected ? Border.all(color: AppTheme.connectedGreen.withOpacity(0.5), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFlagWidget(countryCode),
          const SizedBox(width: 16),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  CountryDetector.getCountryName(countryCode),
                  style: TextStyle(fontSize: 13, color: AppTheme.systemGray),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.primaryBlue.withOpacity(0.12),
                      ),
                      child: Text(
                        config.protocolDisplay,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                      ),
                    ),
                    if (!isConnected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppTheme.warningOrange.withOpacity(0.12),
                        ),
                        child: Text(
                          'Selected',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.warningOrange),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic status, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Upload', AppTheme.formatSpeed(status.uploadSpeed), CupertinoIcons.arrow_up, AppTheme.connectedGreen, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Download', AppTheme.formatSpeed(status.downloadSpeed), CupertinoIcons.arrow_down, AppTheme.primaryBlue, isDark)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Uploaded', AppTheme.formatBytes(status.upload), CupertinoIcons.cloud_upload, AppTheme.warningOrange, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Downloaded', AppTheme.formatBytes(status.download), CupertinoIcons.cloud_download, const Color(0xFFAF52DE), isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color.withOpacity(0.12),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 12, color: AppTheme.systemGray)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConnectionToggle(V2RayService service) async {
    setState(() => _isConnecting = true);
    try {
      if (service.isConnected) {
        await service.disconnect();
      } else {
        final selectedConfig = await service.loadSelectedConfig();
        if (selectedConfig == null) {
          final configs = await service.loadConfigs();
          if (configs.isEmpty) {
            _showSnackBar('No Servers', 'Please add servers from Subscriptions');
          } else {
            _showSnackBar('No Server Selected', 'Please select a server first');
          }
        } else {
          setState(() => _selectedConfig = selectedConfig);
          final success = await service.connect(selectedConfig);
          if (!success) _showSnackBar('Connection Failed', 'Failed to connect');
        }
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
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
}

class _RingPainter extends CustomPainter {
  final bool isConnected;
  final double progress;

  _RingPainter({required this.isConnected, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    
    final bgPaint = Paint()
      ..color = (isConnected ? AppTheme.connectedGreen : AppTheme.primaryBlue).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    final fgPaint = Paint()
      ..shader = SweepGradient(
        colors: isConnected
            ? [AppTheme.connectedGreen.withOpacity(0.2), AppTheme.connectedGreen]
            : [AppTheme.primaryBlue.withOpacity(0.2), AppTheme.primaryBlue],
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
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.isConnected != isConnected || oldDelegate.progress != progress;
  }
}
