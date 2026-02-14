import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/agent_type_mapper.dart';

/// Multi-tabbed bottom sheet for live Multi-Agent insights.
/// Data source: Supabase `agent_insights` realtime stream.
class AgentChatBottomSheet extends StatefulWidget {
  const AgentChatBottomSheet({
    super.key,
    required this.currentUserId,
  });

  final String currentUserId;

  @override
  State<AgentChatBottomSheet> createState() => _AgentChatBottomSheetState();
}

class _AgentChatBottomSheetState extends State<AgentChatBottomSheet> {
  final TextEditingController _inputController = TextEditingController();
  final List<_LocalChatMessage> _localMessages = [];
  bool _isSending = false;
  String? _sendError;
  int _activeTabIndex = 0;

  static const List<_AgentTab> _tabs = [
    _AgentTab(label: '🏥 Health', type: AgentTypeMapper.health),
    _AgentTab(label: '🗺️ Routing', type: AgentTypeMapper.routing),
    _AgentTab(label: '📅 Scheduler', type: AgentTypeMapper.scheduler),
    _AgentTab(label: '🌍 Community', type: AgentTypeMapper.community),
    _AgentTab(label: '⚙️ Admin', type: AgentTypeMapper.admin),
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  String _formatTimestamp(dynamic createdAt) {
    if (createdAt == null) return '';
    final parsed = DateTime.tryParse(createdAt.toString());
    if (parsed == null) return '';
    final local = parsed.toLocal();
    final hour12 = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $suffix';
  }

  List<Map<String, dynamic>> _filterByAgent(
    List<Map<String, dynamic>> allRows,
    String agentType,
  ) {
    return allRows.where((row) {
      final normalized = AgentTypeMapper.normalize(row['agent_type']);
      if (agentType == AgentTypeMapper.admin) {
        return normalized == AgentTypeMapper.admin ||
            normalized == AgentTypeMapper.other;
      }
      return normalized == agentType;
    }).toList();
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<String?> _fetchAnswerTextForQuery(int queryId) async {
    final client = Supabase.instance.client;

    // Primary expected match: agent_answers.query_id = agent_queries.id
    final byQueryId = await client
        .from('agent_answers')
        .select('answer_text')
        .eq('query_id', queryId)
        .maybeSingle();
    final byQueryText = (byQueryId?['answer_text'] ?? '').toString().trim();
    if (byQueryText.isNotEmpty) return byQueryText;

    // Fallback for schemas where ids are aligned directly.
    final byId = await client
        .from('agent_answers')
        .select('answer_text')
        .eq('id', queryId)
        .maybeSingle();
    final byIdText = (byId?['answer_text'] ?? '').toString().trim();
    if (byIdText.isNotEmpty) return byIdText;

    return null;
  }

  Future<String?> _waitForAgentAnswer({required int queryId}) async {
    final client = Supabase.instance.client;
    final completer = Completer<String?>();
    final channelName = 'agent-answers-$queryId-${DateTime.now().microsecondsSinceEpoch}';
    var resolved = false;
    Timer? pollTimer;
    Timer? timeoutTimer;
    RealtimeChannel? channel;

    Future<void> resolve(String? value) async {
      if (resolved) return;
      resolved = true;
      pollTimer?.cancel();
      timeoutTimer?.cancel();
      if (channel != null) {
        await client.removeChannel(channel);
      }
      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }

    Future<void> tryFetchNow() async {
      try {
        final answerText = await _fetchAnswerTextForQuery(queryId);
        if (answerText != null) {
          await resolve(answerText);
        }
      } catch (error) {
        debugPrint('agent_answers fetch error for query=$queryId: $error');
      }
    }

    await tryFetchNow();
    if (resolved) return completer.future;

    void handlePayload(PostgresChangePayload payload) {
      final row = payload.newRecord;
      if (row.isEmpty) return;

      final rowQueryId = _asInt(row['query_id']);
      final rowId = _asInt(row['id']);
      if (rowQueryId != queryId && rowId != queryId) return;

      final answerText = (row['answer_text'] ?? '').toString().trim();
      if (answerText.isEmpty) return;
      unawaited(resolve(answerText));
    }

    channel = client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'agent_answers',
          callback: handlePayload,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'agent_answers',
          callback: handlePayload,
        )
        .subscribe();

    pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(tryFetchNow());
    });

    timeoutTimer = Timer(const Duration(seconds: 60), () {
      unawaited(resolve(null));
    });

    return completer.future;
  }

  Future<void> _sendQuestion() async {
    if (_isSending) return;
    final question = _inputController.text.trim();
    if (question.isEmpty) return;
    final session = Supabase.instance.client.auth.currentSession;
    final authUserId = Supabase.instance.client.auth.currentUser?.id;
    if (session == null || authUserId == null) {
      setState(() {
        _sendError = 'Session expired. Please log in again.';
      });
      debugPrint('send question blocked: no active session');
      return;
    }
    debugPrint(
      'send question auth user=$authUserId widget user=${widget.currentUserId}',
    );
    if (authUserId != widget.currentUserId) {
      debugPrint(
        'warning: auth user differs from chat widget user id, this may fail RLS',
      );
    }

    final tab = _tabs[_activeTabIndex];
    final timestamp = DateTime.now();
    final loadingId = 'loading-${timestamp.microsecondsSinceEpoch}';

    setState(() {
      _sendError = null;
      _isSending = true;
      _localMessages.add(
        _LocalChatMessage(
          id: 'user-${timestamp.microsecondsSinceEpoch}',
          tabType: tab.type,
          originTabType: tab.type,
          message: question,
          timestamp: timestamp,
          fromUser: true,
        ),
      );
      _localMessages.add(
        _LocalChatMessage(
          id: loadingId,
          tabType: tab.type,
          originTabType: tab.type,
          message: 'Thinking...',
          timestamp: DateTime.now(),
          isLoading: true,
        ),
      );
      _inputController.clear();
    });

    try {
      final inserted = await Supabase.instance.client
          .from('agent_queries')
          .insert({
            'user_id': widget.currentUserId,
            'question': question,
            'agent_type': tab.type,
          })
          .select('id')
          .single();
      final queryId = _asInt(inserted['id']);
      if (queryId == null) {
        throw const PostgrestException(
          message: 'agent_queries insert returned no id',
        );
      }
      debugPrint(
        'agent_queries insert succeeded query_id=$queryId user=${widget.currentUserId} tab=${tab.type}',
      );

      final answerText = await _waitForAgentAnswer(queryId: queryId);

      if (!mounted) return;
      setState(() {
        _localMessages.removeWhere((m) => m.id == loadingId);
        _localMessages.add(
          _LocalChatMessage(
            id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
            tabType: tab.type,
            originTabType: tab.type,
            message: (answerText ?? '').isEmpty
                ? 'Response is taking longer than expected. Please check back shortly.'
                : answerText!,
            timestamp: DateTime.now(),
            isWarning: false,
          ),
        );
      });
    } on PostgrestException catch (postgrestError) {
      debugPrint(
        'agent_queries insert/read failed code=${postgrestError.code} message=${postgrestError.message} details=${postgrestError.details}',
      );
      if (mounted) {
        setState(() {
          _localMessages.removeWhere((m) => m.id == loadingId);
          _sendError =
              'Could not send question. Verify agent_queries/agent_answers access and RLS.';
        });
      }
    } catch (error) {
      debugPrint('unexpected send question error: $error');
      if (mounted) {
        setState(() {
          _localMessages.removeWhere((m) => m.id == loadingId);
          _sendError =
              'Could not send question. Verify agent_queries/agent_answers configuration.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return DefaultTabController(
      length: _tabs.length,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.80,
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0D1B1E).withOpacity(0.92),
                      AppTheme.darkBackground.withOpacity(0.94),
                    ],
                  ),
                  border: Border.all(
                    color: AppTheme.neonMint.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildDragHandle(),
                    const SizedBox(height: 10),
                    _buildHeader(),
                    const SizedBox(height: 10),
                    _buildTabBar(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: Supabase.instance.client
                            .from('agent_insights')
                            .stream(primaryKey: ['id'])
                            .eq('user_id', widget.currentUserId)
                            .order('created_at', ascending: false),
                        builder: (context, snapshot) {
                          if (kDebugMode) {
                            debugPrint(
                              'agent_insights stream state=${snapshot.connectionState} hasError=${snapshot.hasError} rows=${snapshot.data?.length ?? 0}',
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Could not load agent insights.\nCheck network or permissions.',
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: AppTheme.errorColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.neonMint,
                              ),
                            );
                          }

                          final allRows = snapshot.data!;
                          return TabBarView(
                            children: _tabs.map((tab) {
                              final filtered = _filterByAgent(allRows, tab.type);
                              final localForTab = _localMessages
                                  .where(
                                    (m) =>
                                        m.tabType == tab.type ||
                                        m.originTabType == tab.type,
                                  )
                                  .toList()
                                  .reversed
                                  .toList();

                              if (filtered.isEmpty && localForTab.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Text(
                                      'No insights from ${tab.label} yet.',
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                itemCount: localForTab.length + filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  if (index < localForTab.length) {
                                    return _buildLocalBubble(localForTab[index]);
                                  }

                                  final item = filtered[index - localForTab.length];
                                  final isWarning =
                                      (item['is_warning'] as bool?) ?? false;
                                  return _buildInsightBubble(
                                    message: (item['message'] ?? '').toString(),
                                    isWarning: isWarning,
                                    timestamp: _formatTimestamp(item['created_at']),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    _buildInputBar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 54,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.psychology_alt_rounded,
            color: AppTheme.neonMint.withOpacity(0.9),
          ),
          const SizedBox(width: 8),
          Text(
            'Multi-Agent Feed',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            'Realtime',
            style: GoogleFonts.inter(
              color: AppTheme.neonMint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      onTap: (index) {
        if (!mounted) return;
        setState(() {
          _activeTabIndex = index;
          _sendError = null;
        });
      },
      isScrollable: true,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      indicator: BoxDecoration(
        color: AppTheme.neonMint.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.neonMint.withOpacity(0.45)),
      ),
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: AppTheme.neonMint,
      unselectedLabelColor: AppTheme.textSecondary,
      tabs: _tabs
          .map(
            (tab) => Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Text(
                  tab.label,
                  style:
                      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInsightBubble({
    required String message,
    required bool isWarning,
    required String timestamp,
  }) {
    final borderColor =
        isWarning ? const Color(0xFFFFB74D) : AppTheme.neonMint.withOpacity(0.35);
    final glowColor = isWarning
        ? const Color(0xFFFF8A65).withOpacity(0.18)
        : AppTheme.neonMint.withOpacity(0.10);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.isEmpty ? 'No content' : message,
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              timestamp,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary.withOpacity(0.82),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalBubble(_LocalChatMessage local) {
    final isUser = local.fromUser;
    final borderColor = local.isLoading
        ? AppTheme.textSecondary.withOpacity(0.45)
        : isUser
            ? AppTheme.neonMint.withOpacity(0.6)
            : local.isWarning
                ? const Color(0xFFFFB74D)
                : AppTheme.neonMint.withOpacity(0.35);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isUser
            ? AppTheme.neonMint.withOpacity(0.10)
            : Colors.white.withOpacity(0.06),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? 'You' : (local.isLoading ? 'Agent' : 'Agent Reply'),
                  style: GoogleFonts.inter(
                    color: isUser ? AppTheme.neonMint : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  local.message,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTimestamp(local.timestamp.toIso8601String()),
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary.withOpacity(0.82),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (local.isLoading)
            const Padding(
              padding: EdgeInsets.only(left: 10, top: 8),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.neonMint,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_sendError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _sendError!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.errorColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  enabled: !_isSending,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ask your agents a question...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendQuestion(),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.neonMint.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.neonMint.withOpacity(0.6)),
                ),
                child: IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.neonMint,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  color: AppTheme.neonMint,
                  onPressed: _isSending ? null : _sendQuestion,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgentTab {
  const _AgentTab({required this.label, required this.type});

  final String label;
  final String type;
}

class _LocalChatMessage {
  const _LocalChatMessage({
    required this.id,
    required this.tabType,
    required this.originTabType,
    required this.message,
    required this.timestamp,
    this.fromUser = false,
    this.isWarning = false,
    this.isLoading = false,
  });

  final String id;
  final String tabType;
  final String originTabType;
  final String message;
  final DateTime timestamp;
  final bool fromUser;
  final bool isWarning;
  final bool isLoading;
}
