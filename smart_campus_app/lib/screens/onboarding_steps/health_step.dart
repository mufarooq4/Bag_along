import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/glass_card.dart';

/// Step 3: Lifestyle & Goals (Health & Community Agents)
/// Collects fitness goals, allergies, daily step goal, and event attendance
class HealthStep extends StatelessWidget {
  const HealthStep({super.key});

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
                'Tell us about your health goals and campus lifestyle preferences',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Fitness Goal Dropdown
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
                            Icons.fitness_center_rounded,
                            color: AppTheme.neonMint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Fitness Goal',
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
                      initialValue: provider.fitnessGoal,
                      decoration: InputDecoration(
                        hintText: 'Select your fitness goal',
                        filled: true,
                        fillColor: AppTheme.darkBackground.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor: AppTheme.cardBackground,
                      style: GoogleFonts.inter(color: AppTheme.textPrimary),
                      items: [
                        'Weight Loss',
                        'Muscle Gain',
                        'General Fitness',
                        'Endurance Training',
                        'Stress Management',
                      ].map((goal) {
                        return DropdownMenuItem(
                          value: goal,
                          child: Text(goal),
                        );
                      }).toList(),
                      onChanged: (value) {
                        provider.setFitnessGoal(value);
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Allergies Checkboxes
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
                            Icons.health_and_safety_outlined,
                            color: AppTheme.neonMint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Environmental Allergies',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select any allergies we should monitor',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Allergy options
                    ...[
                      {'name': 'Dust', 'icon': Icons.grain_rounded},
                      {'name': 'Pollen', 'icon': Icons.local_florist_rounded},
                      {'name': 'Mold', 'icon': Icons.water_damage_rounded},
                      {'name': 'Pet Dander', 'icon': Icons.pets_rounded},
                    ].map((allergy) {
                      final allergyName = allergy['name'] as String;
                      final isSelected = provider.allergies.contains(allergyName);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => provider.toggleAllergy(allergyName),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.neonMint.withOpacity(0.1)
                                  : AppTheme.darkBackground.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.neonMint
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  allergy['icon'] as IconData,
                                  color: isSelected
                                      ? AppTheme.neonMint
                                      : AppTheme.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    allergyName,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: isSelected
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.neonMint,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Daily Step Goal Slider
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
                            Icons.directions_walk_rounded,
                            color: AppTheme.neonMint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Daily Step Goal',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Step count display
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '${provider.dailyStepGoal.toInt()}',
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neonMint,
                            ),
                          ),
                          Text(
                            'steps per day',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Slider
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.neonMint,
                        inactiveTrackColor: AppTheme.textSecondary.withOpacity(0.3),
                        thumbColor: AppTheme.neonMint,
                        overlayColor: AppTheme.neonMint.withOpacity(0.2),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: provider.dailyStepGoal,
                        min: 1000,
                        max: 20000,
                        divisions: 19,
                        onChanged: (value) {
                          provider.setDailyStepGoal(value);
                        },
                      ),
                    ),
                    
                    // Min/Max labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1,000',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '20,000',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Campus Events Attendance
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
                            Icons.event_rounded,
                            color: AppTheme.neonMint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Campus Events Interest',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help us notify you about hackathons, talks, and social gatherings',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Event attendance options
                    ...[
                      {
                        'name': 'Active Attendee',
                        'icon': Icons.celebration_rounded,
                        'description': 'I love attending campus events!'
                      },
                      {
                        'name': 'Occasionally',
                        'icon': Icons.calendar_today_rounded,
                        'description': 'I attend when something interests me'
                      },
                      {
                        'name': 'Rarely',
                        'icon': Icons.notifications_off_outlined,
                        'description': 'I prefer minimal event notifications'
                      },
                    ].map((attendance) {
                      final attendanceName = attendance['name'] as String;
                      final isSelected = provider.eventAttendance == attendanceName;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => provider.setEventAttendance(attendanceName),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.neonMint.withOpacity(0.1)
                                  : AppTheme.darkBackground.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.neonMint
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.neonMint.withOpacity(0.2)
                                        : AppTheme.textSecondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    attendance['icon'] as IconData,
                                    color: isSelected
                                        ? AppTheme.neonMint
                                        : AppTheme.textSecondary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        attendanceName,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? AppTheme.textPrimary
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        attendance['description'] as String,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.neonMint,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
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
