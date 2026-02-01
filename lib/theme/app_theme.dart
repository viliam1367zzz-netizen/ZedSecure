import 'package:flutter/material.dart';

class AppTheme {
  // Ocean Theme Colors
  static const Color oceanBlue = Color(0xFF0099FF);
  static const Color oceanCyan = Color(0xFF00C8C8);
  static const Color oceanDeep = Color(0xFF006699);
  static const Color oceanLight = Color(0xFF00BFFF);
  static const Color oceanGlow = Color(0xFF00D4FF);
  
  // Background Colors
  static const Color darkBg = Color(0xFF0A1628);
  static const Color darkBg2 = Color(0xFF061220);
  static const Color darkCard = Color(0xFF0D1A2D);
  static const Color darkCard2 = Color(0xFF102030);
  
  // Status Colors
  static const Color connectedGreen = Color(0xFF00C8C8);
  static const Color disconnectedRed = Color(0xFFFF4757);
  static const Color warningOrange = Color(0xFFFF9500);
  
  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B8C4);
  static const Color textMuted = Color(0xFF6B7280);
  
  // System Colors
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  
  // Gradients
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [oceanBlue, oceanCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [darkBg, darkBg2, Color(0xFF020810)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [
      Color(0x26009AFF),
      Color(0x1A00C8C8),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Theme
  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: oceanBlue,
      scaffoldBackgroundColor: darkBg,
      fontFamily: 'SF Pro Display',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: oceanBlue,
        secondary: oceanCyan,
        surface: darkCard,
      ),
    );
  }

  // Ocean Glow Decoration
  static BoxDecoration oceanGlowDecoration({
    Color color = oceanBlue,
    double borderRadius = 20,
    double glowIntensity = 0.3,
    double glowBlur = 20,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: darkCard,
      border: Border.all(
        color: color.withOpacity(0.4),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(glowIntensity),
          blurRadius: glowBlur,
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Ocean Card Decoration
  static BoxDecoration oceanCardDecoration({
    Color? borderColor,
    double borderRadius = 24,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: cardGradient,
      border: Border.all(
        color: borderColor ?? oceanBlue.withOpacity(0.25),
        width: 1,
      ),
    );
  }

  // Glass Effect Decoration
  static BoxDecoration glassDecoration({
    double borderRadius = 20,
    Color borderColor = oceanBlue,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: darkCard.withOpacity(0.8),
      border: Border.all(
        color: borderColor.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  // Ocean Button Decoration
  static BoxDecoration oceanButtonDecoration({
    Color color = oceanBlue,
    double borderRadius = 50,
    bool isActive = true,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: isActive ? LinearGradient(
        colors: [color, oceanCyan],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ) : null,
      color: isActive ? null : darkCard,
      border: Border.all(
        color: color.withOpacity(isActive ? 0.5 : 0.3),
        width: 2,
      ),
      boxShadow: isActive ? [
        BoxShadow(
          color: color.withOpacity(0.4),
          blurRadius: 25,
          spreadRadius: 0,
        ),
      ] : null,
    );
  }

  // Ocean Text Style
  static TextStyle oceanTextStyle({
    Color color = textPrimary,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    bool withGlow = false,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      shadows: withGlow ? [
        Shadow(
          color: color.withOpacity(0.6),
          blurRadius: 10,
        ),
      ] : null,
    );
  }

  // Ping Color
  static Color getPingColor(int? ping) {
    if (ping == null || ping < 0) return systemGray;
    if (ping < 100) return connectedGreen;
    if (ping < 200) return oceanBlue;
    if (ping < 400) return warningOrange;
    return disconnectedRed;
  }

  // Format Speed
  static String formatSpeed(int? bytesPerSecond) {
    if (bytesPerSecond == null || bytesPerSecond <= 0) return '0 B/s';
    
    const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    int unitIndex = 0;
    double speed = bytesPerSecond.toDouble();
    
    while (speed >= 1024 && unitIndex < units.length - 1) {
      speed /= 1024;
      unitIndex++;
    }
    
    if (speed >= 100) {
      return '${speed.toStringAsFixed(0)} ${units[unitIndex]}';
    } else if (speed >= 10) {
      return '${speed.toStringAsFixed(1)} ${units[unitIndex]}';
    } else {
      return '${speed.toStringAsFixed(2)} ${units[unitIndex]}';
    }
  }

  // Format Bytes
  static String formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    if (size >= 100) {
      return '${size.toStringAsFixed(0)} ${units[unitIndex]}';
    } else if (size >= 10) {
      return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
    } else {
      return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
    }
  }

  // Format Duration
  static String formatDuration(String? duration) {
    if (duration == null || duration.isEmpty) return '00:00:00';
    return duration;
  }
}

// Ocean Glass Container Widget
class OceanGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final bool withGlow;

  const OceanGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.borderColor,
    this.withGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: AppTheme.darkCard.withOpacity(0.8),
        border: Border.all(
          color: (borderColor ?? AppTheme.oceanBlue).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: withGlow ? [
          BoxShadow(
            color: (borderColor ?? AppTheme.oceanBlue).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ] : null,
      ),
      child: child,
    );
  }
}
