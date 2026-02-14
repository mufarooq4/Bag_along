import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import 'auth_gate.dart';

/// Splash screen with animated logo and tagline
/// Displays for 3 seconds before transitioning to AuthGate
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Start animation
    _animationController.forward();

    // Navigate to auth gate after splash completes.
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthGate(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackground,
              AppTheme.deepForestGreen.withOpacity(0.3),
              AppTheme.darkBackground,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.neonMint,
                              AppTheme.deepForestGreen,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonMint.withOpacity(0.5),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // App Name
                      Text(
                        'Bag Along',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Tagline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          'Your Campus. Your Environment. Your Bag Along.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.neonMint,
                            letterSpacing: 0.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Loading indicator
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.neonMint.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
