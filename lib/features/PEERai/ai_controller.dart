import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import 'gemini_service.dart';

class PeerAiMessage {
  final String role;
  final String text;
  final String? pdfName;
  final int? pdfSize;
  final DateTime timestamp;

  PeerAiMessage({
    required this.role,
    required this.text,
    this.pdfName,
    this.pdfSize,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'text': text,
      'pdfName': pdfName,
      'pdfSize': pdfSize,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PeerAiMessage.fromJson(Map<String, dynamic> json) {
    return PeerAiMessage(
      role: json['role'] as String,
      text: json['text'] as String,
      pdfName: json['pdfName'] as String?,
      pdfSize: json['pdfSize'] as int?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class PeerAiSession {
  final String id;
  final String title;
  final List<PeerAiMessage> messages;
  final DateTime createdAt;

  PeerAiSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PeerAiSession.fromJson(Map<String, dynamic> json) {
    return PeerAiSession(
      id: json['id'] as String,
      title: json['title'] as String,
      messages: (json['messages'] as List)
          .map((m) => PeerAiMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  PeerAiSession copyWith({
    String? id,
    String? title,
    List<PeerAiMessage>? messages,
    DateTime? createdAt,
  }) {
    return PeerAiSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PeerAiState {
  final List<PeerAiSession> sessions;
  final String? activeSessionId;
  final bool isLoading;
  final String? errorMessage;

  PeerAiState({
    required this.sessions,
    this.activeSessionId,
    this.isLoading = false,
    this.errorMessage,
  });

  PeerAiState copyWith({
    List<PeerAiSession>? sessions,
    String? activeSessionId,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PeerAiState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final peerAiControllerProvider = StateNotifierProvider<PeerAiController, PeerAiState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  final geminiService = ref.watch(geminiServiceProvider);
  return PeerAiController(prefs, geminiService);
});

class PeerAiController extends StateNotifier<PeerAiState> {
  final SharedPreferences _prefs;
  final GeminiService _geminiService;
  static const String _storageKey = 'peer_ai_chat_sessions';
  static const int _maxSessions = 20;
  static const int _maxMessagesPerSession = 50;

  PeerAiController(this._prefs, this._geminiService)
      : super(PeerAiState(sessions: [])) {
    _loadChatSessions();
  }

  void _loadChatSessions() {
    try {
      final List<String>? serialized = _prefs.getStringList(_storageKey);
      if (serialized != null && serialized.isNotEmpty) {
        final loaded = serialized.map((item) {
          return PeerAiSession.fromJson(jsonDecode(item) as Map<String, dynamic>);
        }).toList();
        
        // Sort sessions by createdAt descending (newest first)
        loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        state = state.copyWith(
          sessions: loaded,
          activeSessionId: loaded.first.id,
        );
      }
    } catch (_) {
      // Gracefully handle corruption or read errors
    }
  }

  Future<void> _saveChatSessions() async {
    // Evict oldest sessions if they exceed the limit
    List<PeerAiSession> currentSessions = List.from(state.sessions);
    currentSessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    while (currentSessions.length > _maxSessions) {
      currentSessions.removeLast(); // Remove the oldest
    }

    final serialized = currentSessions.map((s) => jsonEncode(s.toJson())).toList();
    try {
      await _prefs.setStringList(_storageKey, serialized);
    } catch (_) {
      // In case of storage full / write failure:
      // Trim down to last 5 sessions to free space
      while (currentSessions.length > 5) {
        currentSessions.removeLast();
      }
      final retrySerialized = currentSessions.map((s) => jsonEncode(s.toJson())).toList();
      try {
        await _prefs.setStringList(_storageKey, retrySerialized);
      } catch (_) {
        // Fallback if device is completely out of space
      }
    }
    
    state = state.copyWith(sessions: currentSessions);
  }

  void startNewSession() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newSession = PeerAiSession(
      id: newId,
      title: 'New chat',
      messages: [],
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      sessions: [newSession, ...state.sessions],
      activeSessionId: newId,
    );
    _saveChatSessions();
  }

  void switchSession(String sessionId) {
    if (state.sessions.any((s) => s.id == sessionId)) {
      state = state.copyWith(activeSessionId: sessionId);
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final updatedSessions = state.sessions.where((s) => s.id != sessionId).toList();
    String? newActiveId = state.activeSessionId;

    if (state.activeSessionId == sessionId) {
      newActiveId = updatedSessions.isNotEmpty ? updatedSessions.first.id : null;
    }

    state = state.copyWith(
      sessions: updatedSessions,
      activeSessionId: newActiveId,
    );
    await _saveChatSessions();
  }

  String _generateTitle(String firstPrompt, String? pdfName) {
    if (pdfName != null) {
      return 'PDF: ${pdfName.length > 15 ? "${pdfName.substring(0, 15)}..." : pdfName}';
    }
    final cleanPrompt = firstPrompt.trim();
    if (cleanPrompt.length <= 25) {
      return cleanPrompt;
    }
    // Take first 3-4 words or 25 characters
    final words = cleanPrompt.split(' ');
    if (words.length > 3) {
      final truncated = '${words[0]} ${words[1]} ${words[2]}...';
      return truncated.length > 25 ? '${cleanPrompt.substring(0, 22)}...' : truncated;
    }
    return '${cleanPrompt.substring(0, 22)}...';
  }

  Future<void> sendMessage({
    required String text,
    String? pdfName,
    int? pdfSize,
    String? base64Pdf,
  }) async {
    if (text.trim().isEmpty && base64Pdf == null) return;

    // Create session if none is active or list is empty
    if (state.activeSessionId == null || state.sessions.isEmpty) {
      startNewSession();
    }

    final activeId = state.activeSessionId!;
    final sessionIndex = state.sessions.indexWhere((s) => s.id == activeId);
    if (sessionIndex == -1) return;

    final activeSession = state.sessions[sessionIndex];

    final userMessage = PeerAiMessage(
      role: 'user',
      text: text.trim().isNotEmpty 
          ? text 
          : (pdfName != null ? 'Summarize the attached PDF: $pdfName' : 'Analyze the attached document.'),
      pdfName: pdfName,
      pdfSize: pdfSize,
      timestamp: DateTime.now(),
    );

    // Update messages in the active session
    final updatedMessages = List<PeerAiMessage>.from(activeSession.messages)..add(userMessage);
    
    // Prune messages in this session if they exceed threshold
    while (updatedMessages.length > _maxMessagesPerSession) {
      updatedMessages.removeAt(0);
    }

    // Auto-update title if it's the first user message
    String updatedTitle = activeSession.title;
    if (activeSession.messages.isEmpty || activeSession.title == 'New chat') {
      updatedTitle = _generateTitle(userMessage.text, pdfName);
    }

    final updatedSession = activeSession.copyWith(
      messages: updatedMessages,
      title: updatedTitle,
    );

    final updatedSessions = List<PeerAiSession>.from(state.sessions);
    updatedSessions[sessionIndex] = updatedSession;

    state = state.copyWith(sessions: updatedSessions, isLoading: true);
    await _saveChatSessions();

    try {
      // Prepare chat history payload for API (Gemini expects user/model roles and text parts)
      final historyPayload = updatedSession.messages.map((m) {
        return {
          'role': m.role,
          'text': m.role == 'user' && m.pdfName != null 
              ? '${m.text}\n[Attached PDF: ${m.pdfName}]' 
              : m.text,
        };
      }).toList();

      final responseText = await _geminiService.sendMessage(
        chatHistory: historyPayload,
        base64Pdf: base64Pdf,
      );

      final modelMessage = PeerAiMessage(
        role: 'model',
        text: responseText,
        timestamp: DateTime.now(),
      );

      // Reload fresh session details after async call finishes
      final freshSessionIndex = state.sessions.indexWhere((s) => s.id == activeId);
      if (freshSessionIndex != -1) {
        final freshSession = state.sessions[freshSessionIndex];
        final finalMessages = List<PeerAiMessage>.from(freshSession.messages)..add(modelMessage);

        final finalSession = freshSession.copyWith(messages: finalMessages);
        final finalSessions = List<PeerAiSession>.from(state.sessions);
        finalSessions[freshSessionIndex] = finalSession;

        state = state.copyWith(sessions: finalSessions, isLoading: false);
        await _saveChatSessions();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> clearChat() async {
    if (state.activeSessionId != null) {
      await deleteSession(state.activeSessionId!);
    }
  }

  void dismissError() {
    state = state.copyWith(errorMessage: null);
  }
}
