import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/auth_profile_service.dart';
import 'welcome_screen.dart';
import 'onboarding_screen.dart';
import 'main_dashboard_screen.dart';

/// Centralized auth + onboarding router.
/// This is the single source of truth for deciding the landing screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  int _profileCheckVersion = 0;

  void _retryProfileCheck() {
    setState(() {
      _profileCheckVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;

        // Debug signal: AuthGate session evaluation point.
        // debugPrint('AuthGate session: ${session?.user.id}');

        // Unauthenticated users always go to the welcome/login flow.
        if (session == null) {
          return const WelcomeScreen();
        }

        // Authenticated users are routed by onboarding completeness.
        return FutureBuilder<bool>(
          key: ValueKey('${session.user.id}-$_profileCheckVersion'),
          future: AuthProfileService.instance
              .isOnboardingComplete(session.user.id)
              .timeout(const Duration(seconds: 10)),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.darkBackground,
                        AppTheme.deepForestGreen.withOpacity(0.25),
                        AppTheme.darkBackground,
                      ],
                    ),
                  ),
                  child: Center(
                    child: GlassCard(
                      width: 220,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppTheme.neonMint),
                          const SizedBox(height: 12),
                          Text(
                            'Loading your workspace...',
                            style: GoogleFonts.inter(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            if (profileSnapshot.hasError) {
              return Scaffold(
                body: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.darkBackground,
                        AppTheme.deepForestGreen.withOpacity(0.2),
                        AppTheme.darkBackground,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: GlassCard(
                        width: 360,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppTheme.errorColor,
                              size: 36,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Could not load your profile.',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This can happen due to network issues or database permissions (RLS).',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _retryProfileCheck,
                                    child: const Text('Retry'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await Supabase.instance.client.auth.signOut();
                                    },
                                    child: const Text('Sign out'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            final isComplete = profileSnapshot.data ?? false;
            return isComplete
                ? const MainDashboardScreen()
                : const OnboardingScreen();
          },
        );
      },
    );
  }
}
