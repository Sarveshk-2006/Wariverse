import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../navigation/app_routes.dart';

/// Premium Apple-Style Multi-Phase Animated Splash Screen for WariVerse AI.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sparkPulse;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _brandOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _sparkPulse = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic)),
    );

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
    );

    _brandOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();

    // Transition naturally after 1.2s animation finishes
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final targetRoute = userProvider.isAuthenticated ? AppRoutes.shell : AppRoutes.login;
      Navigator.of(context).pushReplacementNamed(targetRoute);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Background Warm Golden Aura Radial Glow
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8 * _sparkPulse.value,
                      colors: [
                        const Color(0xFFF97316).withValues(alpha: 0.25 * _sparkPulse.value),
                        const Color(0xFFD97706).withValues(alpha: 0.10 * _sparkPulse.value),
                        const Color(0xFF0F172A),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Container with Golden Aura Ring
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF97316).withValues(alpha: 0.4 * _sparkPulse.value),
                                blurRadius: 28,
                                spreadRadius: 4 * _sparkPulse.value,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/wariverse_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Brand Title & Tagline Reveal
                    Opacity(
                      opacity: _brandOpacity.value,
                      child: Column(
                        children: [
                          Text(
                            'WariVerse AI',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFF97316),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Safer Wari. Smarter Coordination.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFDBA74),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Multi-Portal Pilgrimage Operations System',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Elegant Progress Indicator
                    Opacity(
                      opacity: _brandOpacity.value,
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
