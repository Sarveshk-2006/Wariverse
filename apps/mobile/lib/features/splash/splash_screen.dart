import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../navigation/app_routes.dart';

/// Premium Apple-Style Multi-Phase Animated Splash Screen for WariVerse AI.
/// Visual duration: 2.4 seconds (2,400 ms).
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
  late Animation<double> _auraGlow;
  late Animation<double> _brandOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Phase 1: Initial Glow (0% - 30%)
    _sparkPulse = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // Phase 2: Logo Reveal (25% - 65%)
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.60, curve: Curves.easeIn),
    );

    // Phase 3: Light Rays & Aura Expansion (50% - 85%)
    _auraGlow = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.85, curve: Curves.easeInOut),
      ),
    );

    // Phase 4: Brand Text Fade-In (60% - 100%)
    _brandOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.95, curve: Curves.easeIn),
    );

    _controller.forward();

    // Phase 5: Smooth Transition after 2,400 ms
    Future.delayed(const Duration(milliseconds: 2400), () {
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
              // Background Warm Saffron & Golden Radial Radiance
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.95 * _sparkPulse.value,
                      colors: [
                        const Color(0xFFF97316).withValues(alpha: 0.28 * _sparkPulse.value),
                        const Color(0xFFD97706).withValues(alpha: 0.12 * _auraGlow.value),
                        const Color(0xFF0F172A),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Official WariVerse Circular Logo with Saffron & Golden Aura
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 144,
                          height: 144,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF97316).withValues(alpha: 0.45 * _auraGlow.value),
                                blurRadius: 32 * _auraGlow.value,
                                spreadRadius: 6 * _auraGlow.value,
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
                    const SizedBox(height: 28),

                    // Brand Typography Reveal
                    Opacity(
                      opacity: _brandOpacity.value,
                      child: Column(
                        children: [
                          Text(
                            'WariVerse AI',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFF97316),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Multi-Portal Pilgrimage Operations System',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 44),

                    // Polished Progress Indicator
                    Opacity(
                      opacity: _brandOpacity.value,
                      child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
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
