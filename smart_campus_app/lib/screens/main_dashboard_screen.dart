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

  List<CircleMarker> _buildHazardCircles(List<Map<String, dynamic>> rows) {
    final circles = <CircleMarker>[];

    for (final row in rows) {
      final lat = _asDouble(row['latitude']);
      final lng = _asDouble(row['longitude']);
      if (lat == null || lng == null) continue;
      final point = LatLng(lat, lng);

      final uv = _asDouble(row['uv_index']) ?? 0;
      if (uv >= 8) {
        final uvSeverity = ((uv - 8) / 3).clamp(0.0, 1.0);
        circles.add(
          CircleMarker(
            point: point,
            radius: 45 + (uvSeverity * 45),
            color: const Color(0xFFFF7043).withOpacity(0.15 + (uvSeverity * 0.25)),
            borderColor: const Color(0xFFFFA726),
            borderStrokeWidth: 1.5,
          ),
        );
      }

      final pm = _asDouble(row['pm_level']) ?? 0;
      if (pm >= 80) {
        final pmSeverity = ((pm - 80) / 70).clamp(0.0, 1.0);
        circles.add(
          CircleMarker(
            point: point,
            radius: 40 + (pmSeverity * 65),
            color: const Color(0xFF8E24AA).withOpacity(0.15 + (pmSeverity * 0.30)),
            borderColor: const Color(0xFFCE93D8),
            borderStrokeWidth: 1.5,
          ),
        );
      }
    }

    return circles;
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
                  ],
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
          final hazardCircles = _buildHazardCircles(rows);

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
                    if (hazardCircles.isNotEmpty)
                      CircleLayer(
                        circles: hazardCircles,
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
                    child: _buildMetricsRow(context),
                  ),
                ),
              ),
              if (hazardCircles.isNotEmpty)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 136,
                  right: 16,
                  child: _buildHazardLegend(),
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

  Widget _buildHazardLegend() {
    Widget chip(Color color, String label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.28),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.65), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        chip(const Color(0xFFFFA726), 'High UV'),
        const SizedBox(height: 6),
        chip(const Color(0xFFCE93D8), 'High PM'),
      ],
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = math.max(150.0, math.min(180.0, screenWidth * 0.44));

    return SizedBox(
      height: 158,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          MetricsCard(
            title: 'Steps',
            value: '4250',
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
            width: cardWidth,
          ),
          const SizedBox(width: 12),
          MetricsCard(
            title: 'UV Index',
            value: '8.5',
            icon: Icons.wb_sunny_rounded,
            color: const Color(0xFFFFA726),
            severity: 0.8,
            width: cardWidth,
          ),
          const SizedBox(width: 12),
          MetricsCard(
            title: 'PM Level',
            value: '45',
            icon: Icons.air_rounded,
            color: const Color(0xFF90A4AE),
            severity: 0.4,
            width: cardWidth,
          ),
        ],
      ),
    );
  }
}
