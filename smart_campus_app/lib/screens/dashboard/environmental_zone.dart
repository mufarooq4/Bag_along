import 'package:flutter/material.dart';

/// Environmental Zone Widget - Represents hot zones on the map
/// Color-coded circles showing UV, PM, or heat danger areas
class EnvironmentalZone extends StatefulWidget {
  final String type; // 'uv', 'pm', 'heat'
  final double severity; // 0.0 - 1.0

  const EnvironmentalZone({
    super.key,
    required this.type,
    required this.severity,
  });

  @override
  State<EnvironmentalZone> createState() => _EnvironmentalZoneState();
}

class _EnvironmentalZoneState extends State<EnvironmentalZone>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getZoneColor() {
    switch (widget.type) {
      case 'uv':
        return const Color(0xFFFF6B6B); // Red
      case 'pm':
        return const Color(0xFFFFA726); // Orange
      case 'heat':
        return const Color(0xFFFF9800); // Deep Orange
      default:
        return Colors.red;
    }
  }

  String _getZoneLabel() {
    switch (widget.type) {
      case 'uv':
        return 'High UV';
      case 'pm':
        return 'Poor Air';
      case 'heat':
        return 'Hot Zone';
      default:
        return 'Alert';
    }
  }

  IconData _getZoneIcon() {
    switch (widget.type) {
      case 'uv':
        return Icons.wb_sunny_rounded;
      case 'pm':
        return Icons.air_rounded;
      case 'heat':
        return Icons.thermostat_rounded;
      default:
        return Icons.warning_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getZoneColor();
    final size = 72.0 + (widget.severity * 52);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow circle
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withOpacity(0.26 * widget.severity),
                        color.withOpacity(0.1 * widget.severity),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Inner circle without backdrop blur (keeps map crisp).
                Container(
                  width: size * 0.52,
                  height: size * 0.52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.16),
                    border: Border.all(
                      color: color.withOpacity(0.74),
                      width: 1.8,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getZoneIcon(),
                          color: color,
                          size: 18,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _getZoneLabel(),
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
