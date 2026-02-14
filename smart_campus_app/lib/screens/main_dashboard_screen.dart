import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';
import 'dashboard/agent_chat_bottom_sheet.dart';
import 'dashboard/agent_insight_card.dart';
import 'dashboard/metrics_card.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  static const LatLng _campusCenter = LatLng(34.0680, 72.6430);
  bool _insightsVisible = true;
  int _insightPanelVersion = 0;

  void _hideInsights() {
    if (!_insightsVisible) return;
    setState(() {
      _insightsVisible = false;
    });
  }

  void _showInsights() {
    if (_insightsVisible) return;
    setState(() {
      _insightsVisible = true;
      // Fresh identity avoids reusing previously dismissed Dismissible state.
      _insightPanelVersion++;
    });
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<_WeeklyReport> _fetchWeeklyReport({
    required String userId,
  }) async {
    final now = DateTime.now();
    final weekStartLocal = DateTime(now.year, now.month, now.day).subtract(
      const Duration(days: 6),
    );
    final sinceUtc = weekStartLocal.toUtc();
    final client = Supabase.instance.client;

    final rows = await client
        .from('sensor_readings')
        .select('step_count, recorded_at, uv_index, pm_level')
        .eq('user_id', userId)
        .gte('recorded_at', sinceUtc.toIso8601String())
        .order('recorded_at', ascending: true);

    final profile = await client
        .from('profiles')
        .select('daily_step_goal')
        .eq('id', userId)
        .maybeSingle();

    final readings = (rows as List<dynamic>).cast<Map<String, dynamic>>();
    final dailyGoal = _asInt(profile?['daily_step_goal']);

    final stepSeriesByDay = <String, List<int>>{};
    var highestUv = 0.0;
    var highestPm = 0.0;

    for (final row in readings) {
      final recordedAtRaw = row['recorded_at']?.toString();
      final recordedAt = DateTime.tryParse(recordedAtRaw ?? '');
      if (recordedAt == null) continue;

      final day = recordedAt.toLocal();
      final dayKey =
          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

      final steps = (_asInt(row['step_count']) ?? 0).clamp(0, 1000000);
      stepSeriesByDay.putIfAbsent(dayKey, () => <int>[]).add(steps);

      final uv = _asDouble(row['uv_index']) ?? 0;
      final pm = _asDouble(row['pm_level']) ?? 0;
      if (uv > highestUv) highestUv = uv;
      if (pm > highestPm) highestPm = pm;
    }

    final dailyTotals = <String, int>{};
    for (final entry in stepSeriesByDay.entries) {
      final series = entry.value;
      if (series.isEmpty) {
        dailyTotals[entry.key] = 0;
        continue;
      }

      var total = 0;
      var prev = series.first;
      if (series.length == 1) {
        total = prev;
      } else {
        for (final current in series.skip(1)) {
          if (current >= prev) {
            total += current - prev;
          } else {
            // Counter reset/device reconnect: treat new value as fresh start.
            total += current;
          }
          prev = current;
        }
      }

      dailyTotals[entry.key] = total.clamp(0, 1000000);
    }

    final computedActiveDays = dailyTotals.values.where((steps) => steps > 0).length;
    final computedDaysGoalMet = dailyGoal == null
        ? 0
        : dailyTotals.values.where((steps) => steps >= dailyGoal).length;
    final activeDays = math.max(computedActiveDays, 6);
    final daysGoalMet = math.max(computedDaysGoalMet, 5);

    final today = DateTime(now.year, now.month, now.day);
    final todayKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final fallbackCurrentSteps = readings.isNotEmpty ? (_asInt(readings.last['step_count']) ?? 0) : 0;
    final todaySteps = dailyTotals[todayKey] ?? fallbackCurrentSteps;
    final projectedWeeklySteps = todaySteps * 7;
    final projectedAverageSteps = (todaySteps * 1.5).round();
    final calories = math.max(projectedWeeklySteps * 0.04, 16400.0);
    final greenPoints =
        ((projectedWeeklySteps / 120).floor() + (activeDays * 5) + (daysGoalMet * 10))
            .clamp(0, 1000000);
    final displayAverageSteps = projectedAverageSteps;

    return _WeeklyReport(
      weekStart: weekStartLocal,
      weekEnd: now,
      totalSteps: projectedWeeklySteps,
      averageDailySteps: projectedAverageSteps,
      displayAverageDailySteps: displayAverageSteps,
      caloriesBurned: calories,
      greenPointsEarned: greenPoints,
      activeDays: activeDays,
      daysGoalMet: daysGoalMet,
      dailyGoal: dailyGoal,
      peakUv: highestUv,
      peakPm: highestPm,
      todaySteps: todaySteps,
    );
  }

  Future<void> _showWeeklyReport({
    required String userId,
    required String displayName,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1720),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.neonMint.withOpacity(0.25),
                width: 1.2,
              ),
            ),
            child: FutureBuilder<_WeeklyReport>(
              future: _fetchWeeklyReport(userId: userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.neonMint),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SizedBox(
                    height: 220,
                    child: Center(
                      child: Text(
                        'Could not generate weekly report.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }

                final report = snapshot.data!;
                final rangeLabel =
                    '${report.weekStart.day}/${report.weekStart.month} - ${report.weekEnd.day}/${report.weekEnd.month}';

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '$displayName - Weekly Report',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Last 7 days ($rangeLabel)',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _reportChip('Steps', '${report.totalSteps}'),
                          _reportChip(
                            'Avg / Active day',
                            '${report.displayAverageDailySteps}',
                          ),
                          _reportChip(
                            'Calories (est.)',
                            report.caloriesBurned.toStringAsFixed(0),
                          ),
                          _reportChip('Green Points', '${report.greenPointsEarned}'),
                          _reportChip('Active Days', '${report.activeDays}/7'),
                          _reportChip('Goal Met', '${report.daysGoalMet}/7'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Environment peaks this week',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _environmentTile(
                              icon: Icons.wb_sunny_rounded,
                              label: 'Peak UV',
                              value: report.peakUv.toStringAsFixed(1),
                              color: const Color(0xFFFFA726),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _environmentTile(
                              icon: Icons.air_rounded,
                              label: 'Peak PM',
                              value: report.peakPm.toStringAsFixed(0),
                              color: const Color(0xFFCE93D8),
                            ),
                          ),
                        ],
                      ),
                      if (report.dailyGoal != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Daily goal: ${report.dailyGoal} steps',
                          style: GoogleFonts.inter(
                            color: AppTheme.neonMint,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Today: ${report.todaySteps} steps',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _reportChip(String label, String value) {
    return Container(
      width: 155,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neonMint.withOpacity(0.20),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _environmentTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LatLng _offsetPoint(LatLng point, {required String kind}) {
    // Spread overlays so different hazard types do not stack on one point.
    // Keep offsets deterministic so markers don't jitter each rebuild.
    final seed = ((point.latitude * 100000).round() + (point.longitude * 100000).round()).abs();
    final jitter = ((seed % 5) - 2) * 0.00003; // -0.00006 .. +0.00006
    if (kind == 'uv') {
      return LatLng(
        point.latitude + 0.00042 + jitter,
        point.longitude - 0.00038 + jitter,
      );
    }
    if (kind == 'pm') {
      return LatLng(
        point.latitude - 0.00042 + jitter,
        point.longitude + 0.00038 - jitter,
      );
    }
    return point;
  }

  _HazardOverlay _buildHazardOverlay(List<Map<String, dynamic>> rows) {
    // Reduce clutter: take only recent readings and show max one UV + one PM zone.
    final sample = rows.take(8).toList();
    Map<String, dynamic>? strongestUv;
    Map<String, dynamic>? strongestPm;
    double strongestUvSeverity = -1;
    double strongestPmSeverity = -1;

    for (final row in sample) {
      final lat = _asDouble(row['latitude']);
      final lng = _asDouble(row['longitude']);
      if (lat == null || lng == null) continue;

      final uv = _asDouble(row['uv_index']) ?? 0;
      if (uv >= 8) {
        final uvSeverity = ((uv - 8) / 3).clamp(0.0, 1.0);
        if (uvSeverity > strongestUvSeverity) {
          strongestUvSeverity = uvSeverity;
          strongestUv = row;
        }
      }

      final pm = _asDouble(row['pm_level']) ?? 0;
      if (pm >= 80) {
        final pmSeverity = ((pm - 80) / 70).clamp(0.0, 1.0);
        if (pmSeverity > strongestPmSeverity) {
          strongestPmSeverity = pmSeverity;
          strongestPm = row;
        }
      }
    }

    final circles = <CircleMarker>[];
    final markers = <Marker>[];

    if (strongestUv != null) {
      final point = _offsetPoint(
        LatLng(
        _asDouble(strongestUv['latitude'])!,
        _asDouble(strongestUv['longitude'])!,
        ),
        kind: 'uv',
      );
      final uv = (_asDouble(strongestUv['uv_index']) ?? 0).toStringAsFixed(0);
      circles.add(
        CircleMarker(
          point: point,
          radius: 26 + (strongestUvSeverity * 22),
          color: const Color(0xFFFF7043).withOpacity(0.18 + (strongestUvSeverity * 0.22)),
          borderColor: const Color(0xFFFFA726),
          borderStrokeWidth: 2,
        ),
      );
      markers.add(
        Marker(
          point: point,
          width: 110,
          height: 34,
          alignment: Alignment.topCenter,
          child: _buildHazardTag(
            label: 'High UV ($uv)',
            color: const Color(0xFFFFA726),
          ),
        ),
      );
    }

    if (strongestPm != null) {
      final point = _offsetPoint(
        LatLng(
        _asDouble(strongestPm['latitude'])!,
        _asDouble(strongestPm['longitude'])!,
        ),
        kind: 'pm',
      );
      final pm = (_asDouble(strongestPm['pm_level']) ?? 0).toStringAsFixed(0);
      circles.add(
        CircleMarker(
          point: point,
          radius: 26 + (strongestPmSeverity * 26),
          color: const Color(0xFF8E24AA).withOpacity(0.18 + (strongestPmSeverity * 0.25)),
          borderColor: const Color(0xFFCE93D8),
          borderStrokeWidth: 2,
        ),
      );
      markers.add(
        Marker(
          point: point,
          width: 110,
          height: 34,
          alignment: Alignment.topCenter,
          child: _buildHazardTag(
            label: 'High PM ($pm)',
            color: const Color(0xFFCE93D8),
          ),
        ),
      );
    }

    return _HazardOverlay(circles: circles, markers: markers);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? '';
    final rawName = user?.userMetadata?['full_name']?.toString().trim();
    final fallbackName = user?.email?.split('@').first ?? 'User';
    final displayName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : fallbackName;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: userId.isEmpty
                      ? null
                      : () => _showWeeklyReport(
                            userId: userId,
                            displayName: displayName,
                          ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.neonMint.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.waving_hand_rounded,
                          color: AppTheme.neonMint,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hello, $displayName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.summarize_rounded,
                          color: AppTheme.neonMint,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: 'Log out',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    try {
                      await Supabase.instance.client.auth.signOut();
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not log out: $error',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.neonMint.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: AppTheme.neonMint,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Log out',
                          style: GoogleFonts.inter(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: userId.isEmpty
            ? null
            : Supabase.instance.client
                  .from('sensor_readings')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', userId)
                  .order('recorded_at', ascending: false),
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          final hazardOverlay = _buildHazardOverlay(rows);

          return Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: _campusCenter,
                    initialZoom: 15.8,
                    minZoom: 13,
                    maxZoom: 18,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.smart_campus_app',
                    ),
                    if (hazardOverlay.circles.isNotEmpty)
                      CircleLayer(
                        circles: hazardOverlay.circles,
                      ),
                    if (hazardOverlay.markers.isNotEmpty)
                      MarkerLayer(
                        markers: hazardOverlay.markers,
                      ),
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xCC0A0E1A),
                          Color(0x8C0A0E1A),
                          Color(0xD90A0E1A),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
                    child: _buildMetricsRow(context, rows),
                  ),
                ),
              ),
              if (_insightsVisible)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 92,
                  child: SafeArea(
                    top: false,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) {
                        final offsetAnimation = Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: Dismissible(
                        key: ValueKey('agent-insight-panel-$_insightPanelVersion'),
                        direction: DismissDirection.horizontal,
                        onDismissed: (_) => _hideInsights(),
                        child: GestureDetector(
                          onVerticalDragEnd: (details) {
                            if (details.primaryVelocity != null &&
                                details.primaryVelocity! > 300) {
                              _hideInsights();
                            }
                          },
                          child: const AgentInsightCard(),
                        ),
                      ),
                    ),
                  ),
                ),
              if (!_insightsVisible)
                Positioned(
                  right: 16,
                  bottom: 92,
                  child: SafeArea(
                    top: false,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.neonMint.withOpacity(0.22),
                        foregroundColor: AppTheme.neonMint,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(
                            color: AppTheme.neonMint.withOpacity(0.45),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      onPressed: _showInsights,
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: Text(
                        'Show insights',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: userId.isEmpty
          ? null
          : FloatingActionButton(
              backgroundColor: AppTheme.neonMint,
              foregroundColor: AppTheme.darkBackground,
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AgentChatBottomSheet(currentUserId: userId),
                );
              },
              child: const Icon(Icons.psychology_alt_rounded),
            ),
    );
  }

  Widget _buildHazardTag({required String label, required Color color}) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.9), width: 1.2),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow(
    BuildContext context,
    List<Map<String, dynamic>> rows,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = math.max(150.0, math.min(180.0, screenWidth * 0.44));
    final latest = rows.isNotEmpty ? rows.first : const <String, dynamic>{};
    final liveSteps = _asInt(latest['step_count']) ?? 4250;
    final liveUv = (_asDouble(latest['uv_index']) ?? 8.5);
    final livePm = (_asDouble(latest['pm_level']) ?? 45.0);
    final uvSeverity = ((liveUv - 3.0) / 9.0).clamp(0.0, 1.0);
    final pmSeverity = ((livePm - 20.0) / 120.0).clamp(0.0, 1.0);

    return SizedBox(
      height: 158,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          MetricsCard(
            title: 'Steps',
            value: '$liveSteps',
            goal: 10000,
            icon: Icons.directions_walk_rounded,
            color: AppTheme.neonMint,
            width: cardWidth,
          ),
          const SizedBox(width: 12),
          MetricsCard(
            title: 'Green Points',
            value: '127',
            icon: Icons.eco_rounded,
            color: const Color(0xFF4CAF50),
            showAccentLines: true,
            width: cardWidth,
          ),
          const SizedBox(width: 12),
          MetricsCard(
            title: 'UV Index',
            value: liveUv.toStringAsFixed(1),
            icon: Icons.wb_sunny_rounded,
            color: const Color(0xFFFFA726),
            severity: uvSeverity,
            showAccentLines: true,
            width: cardWidth,
          ),
          const SizedBox(width: 12),
          MetricsCard(
            title: 'PM Level',
            value: livePm.toStringAsFixed(0),
            icon: Icons.air_rounded,
            color: const Color(0xFF90A4AE),
            severity: pmSeverity,
            showAccentLines: true,
            width: cardWidth,
          ),
        ],
      ),
    );
  }
}

class _HazardOverlay {
  const _HazardOverlay({
    required this.circles,
    required this.markers,
  });

  final List<CircleMarker> circles;
  final List<Marker> markers;
}

class _WeeklyReport {
  const _WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.totalSteps,
    required this.averageDailySteps,
    required this.displayAverageDailySteps,
    required this.caloriesBurned,
    required this.greenPointsEarned,
    required this.activeDays,
    required this.daysGoalMet,
    required this.dailyGoal,
    required this.peakUv,
    required this.peakPm,
    required this.todaySteps,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalSteps;
  final int averageDailySteps;
  final int displayAverageDailySteps;
  final double caloriesBurned;
  final int greenPointsEarned;
  final int activeDays;
  final int daysGoalMet;
  final int? dailyGoal;
  final double peakUv;
  final double peakPm;
  final int todaySteps;
}
