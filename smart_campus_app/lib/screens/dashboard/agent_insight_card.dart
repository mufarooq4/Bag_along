import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/agent_type_mapper.dart';

/// Agent Insight Card showing the latest realtime agent insight.
class AgentInsightCard extends StatefulWidget {
  const AgentInsightCard({super.key});

  @override
  State<AgentInsightCard> createState() => _AgentInsightCardState();
}

class _AgentInsightCardState extends State<AgentInsightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      return GlassCard(
        opacity: 0.15,
        blurStrength: 20,
        child: Text(
          'Session expired. Please log in again.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(color: AppTheme.errorColor),
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('agent_insights')
          .stream(primaryKey: ['id'])
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return GlassCard(
            opacity: 0.15,
            blurStrength: 20,
            child: Text(
              'Could not load agent insights. Check network or permissions.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: AppTheme.errorColor),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const GlassCard(
            opacity: 0.15,
            blurStrength: 20,
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.neonMint),
            ),
          );
        }

        final rows = snapshot.data!;
        if (rows.isEmpty) {
          return GlassCard(
            opacity: 0.15,
            blurStrength: 20,
            child: Text(
              'No insights yet. Waiting for Multi-Agent analysis...',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          );
        }

        final topInsights = rows.take(5).toList();
        final hasWarning = topInsights.any(
          (row) => (row['is_warning'] as bool?) ?? false,
        );
        final primaryType = AgentTypeMapper.normalize(
          topInsights.first['agent_type'],
        );
        final cardColor = hasWarning
            ? const Color(0xFFFFB74D)
            : AgentTypeMapper.colorFor(primaryType);

        return GlassCard(
          opacity: 0.15,
          blurStrength: 20,
          borderColor: cardColor.withOpacity(0.32),
          borderWidth: 2,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cardColor,
                            cardColor.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: cardColor.withOpacity(0.35),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        AgentTypeMapper.iconFor(primaryType),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Recommendation',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            hasWarning
                                ? 'Priority Recommendations'
                                : 'Latest Recommendations',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cardColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasWarning)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB74D).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Warning',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFFFFB74D),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cardColor.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...topInsights.map((insight) {
                  final insightType = AgentTypeMapper.normalize(
                    insight['agent_type'],
                  );
                  final message = (insight['message'] ?? '').toString().trim();
                  final isWarning = (insight['is_warning'] as bool?) ?? false;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isWarning
                                ? const Color(0xFFFFB74D)
                                : AgentTypeMapper.colorFor(insightType),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                insightType,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isWarning
                                      ? const Color(0xFFFFCC80)
                                      : AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                message.isEmpty ? 'No content' : message,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                  height: 1.45,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'More Details',
                        Icons.info_outline,
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Detailed insight history in Agent Chat.',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: AppTheme.deepForestGreen,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Open Agents',
                        Icons.chat_bubble_outline_rounded,
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Use the bottom-right AI button to open agents.',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: AppTheme.deepForestGreen,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.neonMint.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.neonMint.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.neonMint, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.neonMint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
