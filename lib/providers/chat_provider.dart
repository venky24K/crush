import 'package:flutter/material.dart';
import 'package:crush/core/services/supabase_service.dart';
import 'package:crush/models/match_model.dart';
import 'package:crush/models/message_model.dart';
import 'package:crush/models/profile_model.dart';

class ChatProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<MatchModel> _matches = [];
  final Map<String, List<MessageModel>> _messagesByMatch = {};
  bool _isLoading = false;

  List<MatchModel> get matches => _matches;
  bool get isLoading => _isLoading;

  int get totalUnreadCount =>
      _matches.where((match) => match.hasUnread).length;

  Future<void> loadMatches(String currentUserId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _matches = await _supabaseService.fetchMatches(currentUserId);
    } catch (e) {
      debugPrint('[ChatProvider] Error fetching matches: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void addMatchFromSwipe(ProfileModel matchedProfile) {
    final newMatch = MatchModel(
      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
      matchedUserId: matchedProfile.id,
      user: matchedProfile,
      createdAt: DateTime.now(),
      lastMessage: 'You matched! Say hello 👋',
      lastMessageAt: DateTime.now(),
      hasUnread: true,
    );

    _matches.insert(0, newMatch);
    notifyListeners();
  }

  List<MessageModel> getMessages(String matchId) {
    return _messagesByMatch[matchId] ?? [];
  }

  Future<void> loadMessages(String matchId) async {
    final messages = await _supabaseService.fetchMessages(matchId);
    _messagesByMatch[matchId] = messages;

    final matchIndex = _matches.indexWhere((m) => m.id == matchId);
    if (matchIndex != -1 && _matches[matchIndex].hasUnread) {
      _matches[matchIndex] = _matches[matchIndex].copyWith(hasUnread: false);
    }

    notifyListeners();
  }

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;

    final newMsg = await _supabaseService.sendMessage(
      matchId: matchId,
      senderId: senderId,
      content: content.trim(),
    );

    if (newMsg != null) {
      final currentList = _messagesByMatch[matchId] ?? [];
      _messagesByMatch[matchId] = [...currentList, newMsg];

      final matchIndex = _matches.indexWhere((m) => m.id == matchId);
      if (matchIndex != -1) {
        _matches[matchIndex] = _matches[matchIndex].copyWith(
          lastMessage: content,
          lastMessageAt: DateTime.now(),
        );
      }

      notifyListeners();
    }
  }
}
