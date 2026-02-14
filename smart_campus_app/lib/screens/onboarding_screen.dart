import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/custom_button.dart';
import '../services/auth_profile_service.dart';
import 'onboarding_steps/profile_academics_step.dart';
import 'onboarding_steps/physical_accessibility_step.dart';
import 'onboarding_steps/health_step.dart';
import 'onboarding_steps/schedule_step.dart';
import 'auth_gate.dart';

/// Multi-step onboarding questionnaire using PageView
/// Collects profile, health, accessibility, schedule, and community preferences
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  final List<String> _stepTitles = [
    'Profile & Academics',
    'Physical & Accessibility',
    'Lifestyle & Goals',
    'Schedule & Data Consent',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _submitOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitOnboarding() async {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    
    if (!provider.isComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please complete all required fields',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Session expired. Please log in again.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
      return;
    }

    try {
      await AuthProfileService.instance.upsertOnboardingProfile(
        userId: user.id,
        onboardingData: provider.toJson(),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome to Bag Along! 🎉',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.deepForestGreen,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final lower = e.message.toLowerCase();
      final isNumericTypeIssue = lower.contains('invalid input syntax for type integer') ||
          lower.contains('height_cm') ||
          lower.contains('weight_kg');
      final friendlyMessage = isNumericTypeIssue
          ? 'Profile data format issue. Please review height and weight values.'
          : e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyMessage,
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save your profile. Please try again.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  bool _canProceed() {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    return _canProceedWithProvider(provider);
  }

  bool _canProceedWithProvider(OnboardingProvider provider) {
    switch (_currentPage) {
      case 0: // Profile & Academics
        return provider.name != null && 
               provider.name!.isNotEmpty &&
               provider.age != null &&
               provider.faculty != null &&
               provider.graduationYear != null;
      case 1: // Physical & Accessibility (no required fields, just defaults)
        return true;
      case 2: // Lifestyle & Goals
        return provider.fitnessGoal != null &&
               provider.eventAttendance != null;
      case 3: // Schedule & Data Consent
        return provider.earliestClassTime != null && 
               provider.campusTransportMethod != null;
      default:
        return false;
    }
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
              AppTheme.deepForestGreen.withOpacity(0.15),
              AppTheme.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with progress
              _buildHeader(),
              
              // Page view with steps
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    ProfileAcademicsStep(),
                    PhysicalAccessibilityStep(),
                    HealthStep(),
                    ScheduleStep(),
                  ],
                ),
              ),
              
              // Bottom navigation
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_currentPage > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppTheme.textPrimary,
                  onPressed: _previousPage,
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Text(
                  'Setup Your Profile',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 24),
          
          // Progress indicator
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentPage
                        ? AppTheme.neonMint
                        : AppTheme.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          
          // Step title
          Text(
            'Step ${_currentPage + 1} of 4',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _stepTitles[_currentPage],
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final canProceed = _canProceedWithProvider(provider);
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground.withOpacity(0.8),
            border: Border(
              top: BorderSide(
                color: AppTheme.textSecondary.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: CustomButton(
                    text: 'Back',
                    onPressed: _previousPage,
                    isOutlined: true,
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 16),
              Expanded(
                flex: _currentPage == 0 ? 1 : 1,
                child: CustomButton(
                  text: _currentPage == 3 ? 'Complete Setup' : 'Continue',
                  onPressed: canProceed ? _nextPage : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please complete all required fields',
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  },
                  isLoading: _isSubmitting,
                  icon: _currentPage == 3 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
