import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

class AppTheme {
  // 🌈 Neon Colors
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonMagenta = Color(0xFFFF00FF);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonPurple = Color(0xFFBF00FF);
  static const Color neonPink = Color(0xFFFF1493);
  static const Color neonBlue = Color(0xFF00BFFF);
  static const Color neonYellow = Color(0xFFFFFF00);
  static const Color neonOrange = Color(0xFFFF6600);

  // 🎨 App Main Colors (Neon Style)
  static const Color primaryBlue = neonCyan;
  static const Color connectedGreen = neonGreen;
  static const Color disconnectedRed = Color(0xFFFF3131);
  static const Color warningOrange = neonOrange;
  
  // 🖤 Dark Background Colors
  static const Color darkBg = Color(0xFF0A0A0F);
  static const Color darkBg2 = Color(0xFF12121A);
  static const Color darkCard = Color(0xFF1A1A25);
  static const Color darkCardBorder = Color(0xFF2A2A3A);

  // ⚪ Gray System
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);

  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: neonCyan,
      scaffoldBackgroundColor: darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: neonCyan),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonGreen,
        surface: darkCard,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: neonCyan,
      scaffoldBackgroundColor: darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: neonCyan),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonGreen,
        surface: darkCard,
      ),
    );
  }

  // ✨ Neon Glow Box Decoration
  static BoxDecoration neonGlowDecoration({
    Color glowColor = neonCyan,
    double borderRadius = 16,
    double glowIntensity = 0.5,
    double glowSpread = 8,
    double glowBlur = 20,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: darkCard,
      border: Border.all(
        color: glowColor.withOpacity(0.6),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(glowIntensity),
          blurRadius: glowBlur,
          spreadRadius: glowSpread,
        ),
        BoxShadow(
          color: glowColor.withOpacity(glowIntensity * 0.5),
          blurRadius: glowBlur * 2,
          spreadRadius: glowSpread * 1.5,
        ),
      ],
    );
  }

  // 🌈 Neon Gradient Decoration
  static BoxDecoration neonGradientDecoration({
    List<Color>? colors,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors ?? [neonCyan.withOpacity(0.3), neonPurple.withOpacity(0.3)],
      ),
      border: Border.all(
        color: neonCyan.withOpacity(0.4),
        width: 1,
      ),
    );
  }

  // 🔲 Glass Decoration with Neon Border
  static BoxDecoration glassDecoration({
    double borderRadius = 16,
    bool isDark = true,
    Color borderColor = neonCyan,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: darkCard.withOpacity(0.7),
      border: Border.all(
        color: borderColor.withOpacity(0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: borderColor.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // 📱 iOS Card with Neon
  static BoxDecoration iosCardDecoration({bool isDark = true}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: darkCard,
      border: Border.all(
        color: neonCyan.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: neonCyan.withOpacity(0.1),
          blurRadius: 15,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // 🏝️ Dynamic Island with Neon
  static BoxDecoration dynamicIslandDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(44),
      color: darkCard,
      border: Border.all(
        color: neonGreen.withOpacity(0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: neonGreen.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 5,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 20,
          spreadRadius: 5,
        ),
      ],
    );
  }

  // 🔘 Neon Button Decoration
  static BoxDecoration neonButtonDecoration({
    Color color = neonCyan,
    double borderRadius = 30,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(isPressed ? 0.4 : 0.2),
          color.withOpacity(isPressed ? 0.2 : 0.1),
        ],
      ),
      border: Border.all(
        color: color.withOpacity(0.8),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(isPressed ? 0.7 : 0.5),
          blurRadius: isPressed ? 30 : 20,
          spreadRadius: isPressed ? 5 : 2,
        ),
      ],
    );
  }

  // 📊 Ping Color
  static Color getPingColor(int? ping) {
    if (ping == null || ping < 0) return systemGray;
    if (ping < 100) return neonGreen;
    if (ping < 300) return neonOrange;
    return disconnectedRed;
  }

  // 📈 Format Speed
  static String formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '$bytesPerSecond B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  // 📦 Format Bytes
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // ✨ Neon Text Style
  static TextStyle neonTextStyle({
    Color color = neonCyan,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      shadows: [
        Shadow(
          color: color.withOpacity(0.8),
          blurRadius: 10,
        ),
        Shadow(
          color: color.withOpacity(0.5),
          blurRadius: 20,
        ),
      ],
    );
  }
}

// ✨ Neon Glass Container Widget
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color glowColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.glowColor = AppTheme.neonCyan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: AppTheme.darkCard.withOpacity(0.6),
              border: Border.all(
                color: glowColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// 🌈 Animated Neon Border Widget
class NeonBorderContainer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<Color> colors;
  final Duration duration;

  const NeonBorderContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.colors = const [
      AppTheme.neonCyan,
      AppTheme.neonPurple,
      AppTheme.neonMagenta,
      AppTheme.neonCyan,
    ],
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<NeonBorderContainer> createState() => _NeonBorderContainerState();
}

class _NeonBorderContainerState extends State<NeonBorderContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: widget.margin,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius + 2),
            gradient: SweepGradient(
              startAngle: _controller.value * 2 * 3.14159,
              colors: widget.colors,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.colors[0].withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              color: AppTheme.darkCard,
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
