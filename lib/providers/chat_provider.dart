import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crush/core/services/supabase_service.dart';
import 'package:crush/models/match_model.dart';
import 'package:crush/models/message_model.dart';
import 'package:crush/models/profile_model.dart';

class ChatProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<MatchModel> _matches = [];
  List<ProfileModel> _incomingLikes = [];
  final Map<String, List<MessageModel>> _messagesByMatch = {};
  bool _isLoading = false;
  bool _isLoadingLikes = false;

  RealtimeChannel? _matchesChannel;
  RealtimeChannel? _currentChatChannel;
  String? _currentUserId;
  String? _activeChatMatchId;

  /// High priority notifier for in-app match alerts (e.g. SnackBars, Dialogs)
  final ValueNotifier<MatchModel?> newMatchNotifier =
      ValueNotifier<MatchModel?>(null);

  List<MatchModel> get matches => _matches;
  List<ProfileModel> get incomingLikes => _incomingLikes;
  bool get isLoading => _isLoading;
  bool get isLoadingLikes => _isLoadingLikes;

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

  Future<void> loadIncomingLikes(String currentUserId) async {
    if (currentUserId.isEmpty) return;
    _isLoadingLikes = true;
    notifyListeners();

    try {
      _incomingLikes = await _supabaseService.fetchIncomingLikes(currentUserId);
    } catch (e) {
      debugPrint('[ChatProvider] Error fetching incoming likes: $e');
    }

    _isLoadingLikes = false;
    notifyListeners();
  }

  Future<MatchModel?> acceptLike({
    required String currentUserId,
    required ProfileModel targetProfile,
  }) async {
    try {
      final isMatch = await _supabaseService.recordSwipe(
        swiperId: currentUserId,
        swipedId: targetProfile.id,
        action: 'like',
      );

      _incomingLikes.removeWhere((p) => p.id == targetProfile.id);

      if (isMatch) {
        final updatedMatches =
            await _supabaseService.fetchMatches(currentUserId);
        _matches = updatedMatches;

        final newMatch = _matches.firstWhere(
          (m) => m.matchedUserId == targetProfile.id,
          orElse: () => MatchModel(
            id: 'match_${DateTime.now().millisecondsSinceEpoch}',
            matchedUserId: targetProfile.id,
            user: targetProfile,
            createdAt: DateTime.now(),
            lastMessageAt: DateTime.now(),
          ),
        );

        notifyListeners();
        return newMatch;
      }

      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('[ChatProvider] Error accepting like: $e');
      return null;
    }
  }

  Future<void> rejectLike({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      await _supabaseService.recordSwipe(
        swiperId: currentUserId,
        swipedId: targetUserId,
        action: 'pass',
      );
      _incomingLikes.removeWhere((p) => p.id == targetUserId);
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatProvider] Error rejecting like: $e');
    }
  }

  /// Subscribe to realtime match creation for the current logged-in user
  void subscribeToMatches(String userId) {
    if (userId.isEmpty) return;
    if (_currentUserId == userId && _matchesChannel != null) return;
    _currentUserId = userId;

    if (_matchesChannel != null) {
      _supabaseService.unsubscribeChannel(_matchesChannel);
      _matchesChannel = null;
    }

    _matchesChannel = _supabaseService.subscribeToUserMatches(userId, (record) async {
      final matchId = record['id'] as String?;
      if (matchId == null) return;

      // Fetch the full match with the other user's profile
      final newMatch = await _supabaseService.fetchMatchById(matchId, userId);
      if (newMatch != null) {
        final existingIndex = _matches.indexWhere((m) => m.id == newMatch.id);
        if (existingIndex == -1) {
          _matches.insert(0, newMatch.copyWith(hasUnread: true));
        } else {
          _matches[existingIndex] = newMatch;
        }

        // Trigger in-app notification banner
        newMatchNotifier.value = newMatch;
        notifyListeners();
      }
    });
  }

  /// Subscribe to live messages inside an active chat session
  void subscribeToChatMessages(String matchId) {
    if (matchId.isEmpty || _activeChatMatchId == matchId) return;
    _activeChatMatchId = matchId;

    if (_currentChatChannel != null) {
      _supabaseService.unsubscribeChannel(_currentChatChannel);
      _currentChatChannel = null;
    }

    _currentChatChannel = _supabaseService.subscribeToMessages(matchId, (msg) {
      final currentList = _messagesByMatch[matchId] ?? [];
      final exists = currentList.any((m) => m.id == msg.id);
      if (!exists) {
        _messagesByMatch[matchId] = [...currentList, msg];

        final matchIndex = _matches.indexWhere((m) => m.id == matchId);
        if (matchIndex != -1) {
          _matches[matchIndex] = _matches[matchIndex].copyWith(
            lastMessage: msg.content,
            lastMessageAt: msg.createdAt,
          );
        }

        notifyListeners();
      }
    });
  }

  /// Unsubscribe from chat messages when leaving ChatScreen
  void unsubscribeFromChatMessages() {
    if (_currentChatChannel != null) {
      _supabaseService.unsubscribeChannel(_currentChatChannel);
      _currentChatChannel = null;
    }
    _activeChatMatchId = null;
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

  @override
  void dispose() {
    if (_matchesChannel != null) {
      _supabaseService.unsubscribeChannel(_matchesChannel);
      _matchesChannel = null;
    }
    if (_currentChatChannel != null) {
      _supabaseService.unsubscribeChannel(_currentChatChannel);
      _currentChatChannel = null;
    }
    newMatchNotifier.dispose();
    super.dispose();
  }
}
