import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/glass_card.dart';

/// Step 2: Physical Metrics & Accessibility
/// Collects height, weight (with unit toggle), and mobility needs
class PhysicalAccessibilityStep extends StatelessWidget {
  const PhysicalAccessibilityStep({super.key});

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
                'Help our Health Agent personalize your wellness tracking and the Routing Agent find accessible paths.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Unit System Toggle
              GlassCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.straighten_rounded,
                      color: AppTheme.neonMint,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Unit System',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBackground.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildUnitButton(
                            context,
                            'Metric',
                            provider.useMetric,
                            () {
                              if (!provider.useMetric) provider.toggleUnitSystem();
                            },
                          ),
                          const SizedBox(width: 4),
                          _buildUnitButton(
                            context,
                            'Imperial',
                            !provider.useMetric,
                            () {
                              if (provider.useMetric) provider.toggleUnitSystem();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Height Slider
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
                            Icons.height_rounded,
                            color: AppTheme.neonMint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Height',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Height display
                    Center(
                      child: Column(
                        children: [
                          Text(
                            provider.useMetric
                                ? '${provider.height.toInt()}'
                                : '${(provider.height ~/ 12)}\'${(provider.height % 12).toInt()}"',
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neonMint,
                            ),
                          ),
                          Text(
                            provider.useMetric ? 'centimeters' : 'feet & inches',
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
                        value: provider.height,
                        min: provider.useMetric ? 120 : 48, // 120cm or 4ft
                        max: provider.useMetric ? 220 : 84, // 220cm or 7ft
                        divisions: provider.useMetric ? 100 : 36,
                        onChanged: (value) => provider.setHeight(value),
                      ),
                    ),
                    
                    // Min/Max labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          provider.useMetric ? '120 cm' : '4\'0"',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          provider.useMetric ? '220 cm' : '7\'0"',
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
              
              // Weight Slider
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
                            Icons.monitor_weight_outlined,
                            color: AppTheme.neonMint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Weight',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Weight display
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '${provider.weight.toInt()}',
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neonMint,
                            ),
                          ),
                          Text(
                            provider.useMetric ? 'kilograms' : 'pounds',
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
                        value: provider.weight,
                        min: provider.useMetric ? 30 : 66, // 30kg or 66lbs
                        max: provider.useMetric ? 200 : 440, // 200kg or 440lbs
                        divisions: provider.useMetric ? 170 : 374,
                        onChanged: (value) => provider.setWeight(value),
                      ),
                    ),
                    
                    // Min/Max labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          provider.useMetric ? '30 kg' : '66 lbs',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          provider.useMetric ? '200 kg' : '440 lbs',
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
              
              // Mobility Needs / Accessibility
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
                            Icons.accessible_forward_rounded,
                            color: AppTheme.neonMint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Accessibility Needs',
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
                      'Optional: Help us suggest accessible routes',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Mobility options
                    ...[
                      {
                        'name': 'None',
                        'icon': Icons.check_circle_outline_rounded,
                        'description': 'No specific accessibility needs'
                      },
                      {
                        'name': 'Wheelchair Accessible Routes',
                        'icon': Icons.wheelchair_pickup_rounded,
                        'description': 'Prefer wheelchair-friendly paths'
                      },
                      {
                        'name': 'Avoid Stairs',
                        'icon': Icons.stairs_rounded,
                        'description': 'Routes with elevators or ramps'
                      },
                      {
                        'name': 'Avoid Steep Inclines',
                        'icon': Icons.terrain_rounded,
                        'description': 'Prefer flat or gentle slopes'
                      },
                    ].map((need) {
                      final needName = need['name'] as String;
                      final isSelected = provider.mobilityNeeds.contains(needName);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => provider.toggleMobilityNeed(needName),
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
                                  need['icon'] as IconData,
                                  color: isSelected
                                      ? AppTheme.neonMint
                                      : AppTheme.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        needName,
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
                                      const SizedBox(height: 2),
                                      Text(
                                        need['description'] as String,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
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
              
              const SizedBox(height: 80), // Space for bottom navigation
            ],
          );
        },
      ),
    );
  }

  Widget _buildUnitButton(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.neonMint
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? AppTheme.darkBackground
                : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
