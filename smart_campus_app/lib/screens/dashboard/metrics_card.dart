import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

/// Metrics Card for displaying user stats with circular progress
/// Used in horizontal scroll on dashboard
class MetricsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final int? goal;
  final IconData icon;
  final Color color;
  final bool showSparkline;
  final double? severity;
  final double width;

  const MetricsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.goal,
    required this.icon,
    required this.color,
    this.showSparkline = false,
    this.severity,
    this.width = 168,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: width,
      opacity: 0.12,
      blurStrength: 15,
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1.0);
          final compact = textScale > 1.1 || constraints.maxHeight < 145;
          final valueFontSize = compact ? 24.0 : 27.0;
          final iconSize = compact ? 18.0 : 20.0;
          final iconBox = compact ? 34.0 : 36.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and severity indicator
              Row(
                children: [
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: iconSize),
                  ),
                  const Spacer(),
                  if (severity != null) _buildSeverityIndicator(compact: compact),
                ],
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: GoogleFonts.poppins(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (goal != null)
                      TextSpan(
                        text: ' / $goal',
                        style: GoogleFonts.inter(
                          fontSize: compact ? 12 : 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: compact ? 11 : 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: compact ? 9 : 10,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),
              const Spacer(),
              if (goal != null) _buildProgressBar() else if (showSparkline) _buildSparkline(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = double.parse(value) / goal!;
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.textSecondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildSparkline() {
    return SizedBox(
      height: 20,
      child: CustomPaint(
        painter: _SparklinePainter(color: color),
        size: const Size.fromHeight(20),
      ),
    );
  }

  Widget _buildSeverityIndicator({required bool compact}) {
    String label;
    Color indicatorColor;

    if (severity! >= 0.8) {
      label = 'High';
      indicatorColor = const Color(0xFFFF6B6B);
    } else if (severity! >= 0.5) {
      label = 'Moderate';
      indicatorColor = const Color(0xFFFFA726);
    } else {
      label = 'Low';
      indicatorColor = const Color(0xFF4CAF50);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w600,
          color: indicatorColor,
        ),
      ),
    );
  }
}

/// Sparkline painter for showing trend
class _SparklinePainter extends CustomPainter {
  final Color color;

  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Generate random sparkline data
    final random = math.Random(42);
    final points = List.generate(10, (i) {
      return Offset(
        size.width * (i / 9),
        size.height * (0.3 + random.nextDouble() * 0.4),
      );
    });

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (var point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
