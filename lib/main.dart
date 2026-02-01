import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zedsecure/services/v2ray_service.dart';
import 'package:zedsecure/services/theme_service.dart';
import 'package:zedsecure/services/app_settings_service.dart';
import 'package:zedsecure/services/update_checker_service.dart';
import 'package:zedsecure/widgets/update_dialog.dart';
import 'package:zedsecure/theme/app_theme.dart';
import 'package:zedsecure/screens/home_screen.dart';
import 'package:zedsecure/screens/servers_screen.dart';
import 'package:zedsecure/screens/subscriptions_screen.dart';
import 'package:zedsecure/screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => V2RayService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AppSettingsService()..loadSettings()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'ZedSecure VPN',
            themeMode: ThemeMode.dark, // Force dark mode for neon
            darkTheme: AppTheme.darkTheme(),
            theme: AppTheme.lightTheme(),
            home: const MainNavigation(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late AnimationController _slideIndicatorController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _slideIndicatorAnimation;

  final List<Widget> _screens = const [
    HomeScreen(),
    ServersScreen(),
    SubscriptionsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _slideIndicatorAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideIndicatorController, curve: Curves.easeInOutCubic),
    );

    _animationController.forward();
    _initializeApp();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final updateInfo = await UpdateCheckerService.checkForUpdates();
    if (updateInfo != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UpdateDialog(updateInfo: updateInfo),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideIndicatorController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final service = Provider.of<V2RayService>(context, listen: false);
    await service.initialize();
  }

  void _onTabTapped(int index) {
    if (_selectedIndex != index) {
      final double begin = _selectedIndex.toDouble();
      final double end = index.toDouble();
      
      _slideIndicatorAnimation = Tween<double>(begin: begin, end: end).animate(
        CurvedAnimation(parent: _slideIndicatorController, curve: Curves.easeInOutCubic),
      );
      
      setState(() => _selectedIndex = index);
      _animationController.reset();
      _animationController.forward();
      _slideIndicatorController.reset();
      _slideIndicatorController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.darkBg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: child,
              ),
            ),
          );
        },
        child: IndexedStack(
          key: ValueKey<int>(_selectedIndex),
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildNeonTabBar(),
    );
  }

  Widget _buildNeonTabBar() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: AppTheme.darkCard.withOpacity(0.95),
                border: Border.all(
                  color: AppTheme.neonCyan.withOpacity(0.3 + (_glowController.value * 0.1)),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonCyan.withOpacity(0.15 + (_glowController.value * 0.05)),
                    blurRadius: 20 + (_glowController.value * 5),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated Neon Indicator
                  AnimatedBuilder(
                    animation: _slideIndicatorAnimation,
                    builder: (context, child) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final tabWidth = (screenWidth - 80) / 4;
                      final indicatorWidth = tabWidth * 0.7;
                      
                      return Positioned(
                        left: 20 + (_slideIndicatorAnimation.value * tabWidth) + (tabWidth - indicatorWidth) / 2,
                        bottom: 8,
                        child: Container(
                          width: indicatorWidth,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.neonCyan,
                                AppTheme.neonPurple,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonCyan.withOpacity(0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTabItem(0, CupertinoIcons.house_fill, 'Home'),
                      _buildTabItem(1, CupertinoIcons.rectangle_stack_fill, 'Servers'),
                      _buildTabItem(2, CupertinoIcons.cloud_fill, 'Subs'),
                      _buildTabItem(3, CupertinoIcons.gear_solid, 'Settings'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppTheme.neonCyan : Colors.white38;
    
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                size: 24,
                color: color,
                shadows: isSelected ? [
                  Shadow(
                    color: AppTheme.neonCyan.withOpacity(0.8),
                    blurRadius: 15,
                  ),
                ] : null,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: color,
                shadows: isSelected ? [
                  Shadow(
                    color: AppTheme.neonCyan.withOpacity(0.8),
                    blurRadius: 10,
                  ),
                ] : null,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
