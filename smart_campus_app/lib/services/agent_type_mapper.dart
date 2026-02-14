import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared mapping between backend `agent_type` strings and UI presentation.
class AgentTypeMapper {
  static const String health = 'Health Agent';
  static const String routing = 'Routing Agent';
  static const String scheduler = 'Scheduler Agent';
  static const String community = 'Community Agent';
  static const String admin = 'Administrator Agent';
  static const String other = 'Other';

  static String normalize(dynamic rawType) {
    final value = (rawType ?? '').toString().trim().toLowerCase();
    if (value == 'health agent' || value == 'health') return health;
    if (value == 'routing agent' || value == 'routing') return routing;
    if (value == 'scheduler agent' || value == 'scheduler') return scheduler;
    if (value == 'community agent' || value == 'community') return community;
    if (value == 'administrator agent' ||
        value == 'admin agent' ||
        value == 'admin') {
      return admin;
    }
    return other;
  }

  static IconData iconFor(String normalizedType) {
    switch (normalizedType) {
      case health:
        return Icons.favorite_rounded;
      case routing:
        return Icons.navigation_rounded;
      case scheduler:
        return Icons.calendar_today_rounded;
      case community:
        return Icons.groups_rounded;
      case admin:
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.psychology_alt_rounded;
    }
  }

  static Color colorFor(String normalizedType) {
    switch (normalizedType) {
      case health:
        return const Color(0xFFFF6B6B);
      case routing:
        return AppTheme.neonMint;
      case scheduler:
        return const Color(0xFF9C27B0);
      case community:
        return const Color(0xFF4CAF50);
      case admin:
        return const Color(0xFFFFA726);
      default:
        return AppTheme.textSecondary;
    }
  }
}
