import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/glass_card.dart';

/// Step 1: Basic Profile & Academics
/// Collects name, age, faculty/major, and graduation year
class ProfileAcademicsStep extends StatelessWidget {
  const ProfileAcademicsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Consumer<OnboardingProvider>(
        builder: (context, provider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Text(
                'Let\'s get to know you better! This helps personalize your campus experience.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Name Field
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.neonMint.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: AppTheme.neonMint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Full Name',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: provider.name,
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        filled: true,
                        fillColor: AppTheme.darkBackground.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.deepForestGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.neonMint,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => provider.setName(value),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Age Field
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.neonMint.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.cake_outlined,
                            color: AppTheme.neonMint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Age',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: provider.age?.toString(),
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Enter your age',
                        suffixText: 'years',
                        suffixStyle: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppTheme.darkBackground.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.deepForestGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.neonMint,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        final age = int.tryParse(value);
                        provider.setAge(age);
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Faculty/Major Dropdown
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.neonMint.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school_outlined,
                            color: AppTheme.neonMint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Faculty / Major',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: provider.faculty,
                      decoration: InputDecoration(
                        hintText: 'Select your faculty',
                        filled: true,
                        fillColor: AppTheme.darkBackground.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.deepForestGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.neonMint,
                            width: 2,
                          ),
                        ),
                      ),
                      dropdownColor: AppTheme.cardBackground,
                      style: GoogleFonts.inter(color: AppTheme.textPrimary),
                      items: [
                        'Computer Engineering',
                        'Electrical Engineering',
                        'Mechanical Engineering',
                        'Civil Engineering',
                        'Management Sciences',
                        'Business Administration',
                        'Computer Science',
                        'Software Engineering',
                        'Data Science',
                        'Environmental Sciences',
                        'Architecture',
                        'Industrial Engineering',
                      ].map((faculty) {
                        return DropdownMenuItem(
                          value: faculty,
                          child: Text(faculty),
                        );
                      }).toList(),
                      onChanged: (value) => provider.setFaculty(value),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Graduation Year Dropdown
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.neonMint.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.event_available_outlined,
                            color: AppTheme.neonMint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Expected Graduation',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: provider.graduationYear,
                      decoration: InputDecoration(
                        hintText: 'Select graduation year',
                        filled: true,
                        fillColor: AppTheme.darkBackground.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.deepForestGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.neonMint,
                            width: 2,
                          ),
                        ),
                      ),
                      dropdownColor: AppTheme.cardBackground,
                      style: GoogleFonts.inter(color: AppTheme.textPrimary),
                      items: [
                        'Class of 2025',
                        'Class of 2026',
                        'Class of 2027',
                        'Class of 2028',
                        'Class of 2029',
                        'Class of 2030',
                      ].map((year) {
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                      onChanged: (value) => provider.setGraduationYear(value),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 80), // Space for bottom navigation
            ],
          );
        },
      ),
    );
  }
}
