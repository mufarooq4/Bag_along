import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/glass_card.dart';

/// Step 4: Schedule & Data Consent
/// Collects earliest class time, campus transport method, and Green Points opt-in
class ScheduleStep extends StatelessWidget {
  const ScheduleStep({super.key});

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
                'Set your schedule preferences and decide on data sharing for Green Points',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Earliest Class Time Picker
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
                            Icons.schedule_rounded,
                            color: AppTheme.neonMint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Earliest Class Time',
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
                      'When does your earliest class typically start?',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: provider.earliestClassTime ??
                              const TimeOfDay(hour: 8, minute: 0),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppTheme.neonMint,
                                  onPrimary: AppTheme.darkBackground,
                                  surface: AppTheme.cardBackground,
                                  onSurface: AppTheme.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        
                        if (picked != null) {
                          provider.setEarliestClassTime(picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBackground.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: provider.earliestClassTime != null
                                ? AppTheme.neonMint
                                : AppTheme.deepForestGreen.withOpacity(0.3),
                            width: provider.earliestClassTime != null ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: AppTheme.neonMint,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              provider.earliestClassTime != null
                                  ? provider.earliestClassTime!.format(context)
                                  : 'Select time',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: provider.earliestClassTime != null
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Campus Transport Method
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
                            Icons.commute_rounded,
                            color: AppTheme.neonMint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Campus Transport',
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
                      'How do you usually get around campus?',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Transport options
                    ...[
                      {
                        'name': 'Walking',
                        'icon': Icons.directions_walk_rounded,
                        'description': 'I walk between classes'
                      },
                      {
                        'name': 'Bicycle',
                        'icon': Icons.pedal_bike_rounded,
                        'description': 'I bike around campus'
                      },
                      {
                        'name': 'Campus Shuttle',
                        'icon': Icons.directions_bus_rounded,
                        'description': 'I use the shuttle service'
                      },
                      {
                        'name': 'Electric Scooter',
                        'icon': Icons.electric_scooter_rounded,
                        'description': 'I use e-scooters'
                      },
                      {
                        'name': 'Car',
                        'icon': Icons.directions_car_rounded,
                        'description': 'I drive my own vehicle'
                      },
                    ].map((transport) {
                      final transportName = transport['name'] as String;
                      final isSelected = provider.campusTransportMethod == transportName;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => provider.setCampusTransportMethod(transportName),
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
                                    transport['icon'] as IconData,
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
                                        transportName,
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
                                        transport['description'] as String,
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
              
              const SizedBox(height: 24),
              
              // Green Points Section (from community_step)
              GlassCard(
                borderColor: AppTheme.neonMint.withOpacity(0.3),
                borderWidth: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.neonMint,
                                AppTheme.deepForestGreen,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonMint.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Green Points',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Sustainability Rewards',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.neonMint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Earn points for sustainable behaviors and redeem them for campus perks!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Data Sharing Toggle
                    InkWell(
                      onTap: () {
                        provider.setGreenPointsOptIn(!provider.greenPointsOptIn);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: provider.greenPointsOptIn
                              ? AppTheme.neonMint.withOpacity(0.1)
                              : AppTheme.darkBackground.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: provider.greenPointsOptIn
                                ? AppTheme.neonMint
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Join Green Points Program',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: provider.greenPointsOptIn
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    provider.greenPointsOptIn
                                        ? 'You\'re contributing to a greener campus!'
                                        : 'Share anonymous data for sustainability',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Transform.scale(
                              scale: 1.2,
                              child: Switch(
                                value: provider.greenPointsOptIn,
                                onChanged: (value) {
                                  provider.setGreenPointsOptIn(value);
                                },
                                activeThumbColor: AppTheme.neonMint,
                                activeTrackColor: AppTheme.neonMint.withOpacity(0.5),
                                inactiveThumbColor: AppTheme.textSecondary,
                                inactiveTrackColor: AppTheme.textSecondary.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Privacy note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.deepForestGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.neonMint,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'All data is anonymized and encrypted. We never share personal information.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
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
