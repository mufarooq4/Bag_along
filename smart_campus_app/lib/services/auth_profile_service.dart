import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles profile completeness checks and onboarding upserts.
/// This keeps AuthGate as the single source of truth for routing decisions.
class AuthProfileService {
  AuthProfileService._();

  static final AuthProfileService instance = AuthProfileService._();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> isOnboardingComplete(String userId) async {
    final profile = await _supabase
        .from('profiles')
        .select(
          'full_name, age, faculty, grad_year, fitness_goal, daily_step_goal, earliest_class, transport_method',
        )
        .eq('id', userId)
        .maybeSingle();

    if (profile == null) return false;

    final fullName = (profile['full_name'] as String?)?.trim();
    return fullName != null &&
        fullName.isNotEmpty &&
        profile['age'] != null &&
        profile['faculty'] != null &&
        profile['grad_year'] != null &&
        profile['fitness_goal'] != null &&
        profile['daily_step_goal'] != null &&
        profile['earliest_class'] != null &&
        profile['transport_method'] != null;
  }

  Future<void> upsertOnboardingProfile({
    required String userId,
    required Map<String, dynamic> onboardingData,
  }) async {
    final heightCmInt = _asInt(onboardingData['height_cm']);
    final weightKgInt = _asInt(onboardingData['weight_kg']);
    final ageInt = _asInt(onboardingData['age']);
    final dailyStepGoalInt = _asInt(onboardingData['daily_step_goal']);
    final mobilityNeeds = _asStringList(onboardingData['mobility_needs']);
    final allergies = _asStringList(onboardingData['allergies']);
    final earliestClass = _normalizeTime(onboardingData['earliest_class_time']);

    await _supabase.from('profiles').upsert({
      'id': userId,
      'full_name': onboardingData['name'],
      'age': ageInt,
      'faculty': onboardingData['faculty'],
      'grad_year': onboardingData['graduation_year'],
      // Defensive casts for INTEGER schema compatibility.
      'height_cm': heightCmInt,
      'weight_kg': weightKgInt,
      'mobility_needs': mobilityNeeds,
      'event_attendance': onboardingData['event_attendance'],
      'fitness_goal': onboardingData['fitness_goal'],
      'daily_step_goal': dailyStepGoalInt,
      'allergies': allergies,
      // Ensure HH:MM for TIME column compatibility.
      'earliest_class': earliestClass,
      'transport_method': onboardingData['campus_transport_method'],
      'share_data': onboardingData['green_points_opt_in'],
    }, onConflict: 'id');
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final parsed = num.tryParse(value.trim());
      return parsed?.round();
    }
    return null;
  }

  List<String> _asStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return const [];
      return [trimmed];
    }
    return [value.toString()];
  }

  String? _normalizeTime(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return raw;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
