import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/glass_card.dart';

/// Step 3: Community & Green Points
/// Explains Green Points program and allows opt-in for anonymous data sharing
class CommunityStep extends StatelessWidget {
  const CommunityStep({super.key});

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
                'Join our campus sustainability initiative',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Green Points Explanation Card
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
                            gradient: LinearGradient(
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
                                  fontSize: 24,
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
                    
                    const SizedBox(height: 24),
                    
                    // Divider
                    Container(
                      height: 1,
                      color: AppTheme.textSecondary.withOpacity(0.1),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // What are Green Points?
                    Text(
                      'What are Green Points?',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Green Points reward you for sustainable behaviors like walking to class, using less energy, and contributing to environmental data collection. Earn points and redeem them for campus perks!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Benefits
                    ...[ 
                      {
                        'icon': Icons.trending_up_rounded,
                        'title': 'Earn Rewards',
                        'description': 'Get points for eco-friendly actions'
                      },
                      {
                        'icon': Icons.store_rounded,
                        'title': 'Redeem Perks',
                        'description': 'Use points at campus stores & cafes'
                      },
                      {
                        'icon': Icons.groups_rounded,
                        'title': 'Build Community',
                        'description': 'Compete with friends & classmates'
                      },
                      {
                        'icon': Icons.public_rounded,
                        'title': 'Make Impact',
                        'description': 'Help create a greener campus'
                      },
                    ].map((benefit) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.neonMint.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                benefit['icon'] as IconData,
                                color: AppTheme.neonMint,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    benefit['title'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    benefit['description'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Data Sharing Opt-in Card
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
                            Icons.shield_outlined,
                            color: AppTheme.neonMint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Anonymous Data Sharing',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Help improve campus sustainability by sharing anonymized environmental data. Your privacy is protected, and you can opt out anytime.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Toggle switch card
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
                                        : 'Tap to enable and start earning points',
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
