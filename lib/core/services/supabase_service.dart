import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crush/core/constants/app_constants.dart';
import 'package:crush/models/match_model.dart';
import 'package:crush/models/message_model.dart';
import 'package:crush/models/profile_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  SupabaseClient? get client {
    if (_isInitialized) {
      try {
        return Supabase.instance.client;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> initialize({String? supabaseUrl, String? supabaseAnonKey}) async {
    final url = supabaseUrl ?? AppConstants.defaultSupabaseUrl;
    final anonKey = supabaseAnonKey ?? AppConstants.defaultSupabaseAnonKey;

    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('[SupabaseService] Connected to Supabase live database successfully!');
    } catch (e) {
      debugPrint('[SupabaseService] Failed to initialize Supabase: $e');
      _isInitialized = false;
    }
  }

  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    if (client == null) return false;
    try {
      return await client!.auth.signInWithOAuth(
        provider,
        redirectTo: kIsWeb ? null : AppConstants.authRedirectUri,
        authScreenLaunchMode:
            kIsWeb ? LaunchMode.platformDefault : LaunchMode.inAppBrowserView,
      );
    } catch (e) {
      debugPrint('[SupabaseService] OAuth error ($provider): $e');
      return false;
    }
  }

  Future<ProfileModel?> getCurrentUserProfile() async {
    if (client == null || client?.auth.currentUser == null) {
      return null;
    }

    try {
      final userId = client!.auth.currentUser!.id;
      final response = await client!
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return ProfileModel.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching profile: $e');
      return null;
    }
  }

  Future<List<ProfileModel>> fetchDiscoveryProfiles({
    required String currentUserId,
    int minAge = 18,
    int maxAge = 50,
    double maxDistanceKm = 100,
    String genderPreference = 'everyone',
  }) async {
    if (client == null) {
      return [];
    }

    try {
      final Set<String> swipedIds = {};
      if (currentUserId.isNotEmpty) {
        final swipedResponse = await client!
            .from('swipes')
            .select('swiped_id')
            .eq('swiper_id', currentUserId);

        for (final row in (swipedResponse as List)) {
          final id = row['swiped_id'] as String?;
          if (id != null) swipedIds.add(id);
        }
      }

      var query = client!.from('profiles').select();
      if (currentUserId.isNotEmpty) {
        query = query.neq('id', currentUserId);
      }

      final response = await query.limit(50);
      final rawList = (response as List)
          .map((json) => ProfileModel.fromJson(json))
          .toList();

      final normalizedPref = genderPreference.trim().toLowerCase();

      return rawList.where((p) {
        // Exclude current user
        if (p.id == currentUserId) return false;

        // Exclude already swiped profiles
        if (swipedIds.contains(p.id)) return false;

        // Gender filter
        final pGender = p.gender.toLowerCase();
        final wantsMen = normalizedPref == 'men' || normalizedPref == 'male';
        final wantsWomen = normalizedPref == 'women' || normalizedPref == 'female';

        if (wantsMen && pGender != 'male') {
          return false;
        }
        if (wantsWomen && pGender != 'female') {
          return false;
        }

        // Age filter
        if (p.age < minAge || p.age > maxAge) {
          return false;
        }

        return true;
      }).toList();
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching discovery: $e');
      return [];
    }
  }

  Future<bool> resetSwipes(String currentUserId) async {
    if (client == null || currentUserId.isEmpty) return false;
    try {
      await client!.from('swipes').delete().eq('swiper_id', currentUserId);
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Error resetting swipes: $e');
      return false;
    }
  }

  Future<bool> recordSwipe({
    required String swiperId,
    required String swipedId,
    required String action,
  }) async {
    if (client == null) return false;

    try {
      await client!.from('swipes').upsert({
        'swiper_id': swiperId,
        'swiped_id': swipedId,
        'action': action,
        'created_at': DateTime.now().toIso8601String(),
      });

      final matchCheck = await client!
          .from('matches')
          .select()
          .or('and(user1_id.eq.$swiperId,user2_id.eq.$swipedId),and(user1_id.eq.$swipedId,user2_id.eq.$swiperId)')
          .maybeSingle();

      return matchCheck != null;
    } catch (e) {
      debugPrint('[SupabaseService] Error recording swipe: $e');
      return false;
    }
  }

  Future<List<MatchModel>> fetchMatches(String currentUserId) async {
    if (client == null || currentUserId.isEmpty) {
      return [];
    }

    try {
      final response = await client!
          .from('matches')
          .select('*, user1:profiles!user1_id(*), user2:profiles!user2_id(*)')
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
          .order('last_message_at', ascending: false);

      return (response as List).map((row) {
        final isUser1Me = row['user1_id'] == currentUserId;
        final otherUserJson = isUser1Me ? row['user2'] : row['user1'];
        final otherProfile = ProfileModel.fromJson(otherUserJson);
        return MatchModel.fromJson(row, otherProfile);
      }).toList();
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching matches: $e');
      return [];
    }
  }

  Future<List<ProfileModel>> fetchIncomingLikes(String currentUserId) async {
    if (client == null || currentUserId.isEmpty) return [];

    try {
      final response = await client!
          .from('swipes')
          .select('swiper_id, action, created_at, swiper:profiles!swiper_id(*)')
          .eq('swiped_id', currentUserId)
          .inFilter('action', ['like', 'superlike'])
          .order('created_at', ascending: false);

      final mySwipes = await client!
          .from('swipes')
          .select('swiped_id')
          .eq('swiper_id', currentUserId);

      final mySwipedIds = (mySwipes as List)
          .map((s) => s['swiped_id']?.toString() ?? '')
          .toSet();

      final List<ProfileModel> likes = [];
      for (final row in response as List) {
        final swiperId = row['swiper_id']?.toString() ?? '';
        if (!mySwipedIds.contains(swiperId) && row['swiper'] != null) {
          try {
            final profile =
                ProfileModel.fromJson(Map<String, dynamic>.from(row['swiper']));
            likes.add(profile);
          } catch (e) {
            debugPrint('[SupabaseService] Parse error on incoming like: $e');
          }
        }
      }
      return likes;
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching incoming likes: $e');
      return [];
    }
  }

  Future<List<MessageModel>> fetchMessages(String matchId) async {
    if (client == null || matchId.isEmpty) {
      return [];
    }

    try {
      final response = await client!
          .from('messages')
          .select()
          .eq('match_id', matchId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching messages: $e');
      return [];
    }
  }

  Future<MessageModel?> sendMessage({
    required String matchId,
    required String senderId,
    required String content,
  }) async {
    final message = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      matchId: matchId,
      senderId: senderId,
      content: content,
      createdAt: DateTime.now(),
      isRead: false,
    );

    if (client == null) {
      return message;
    }

    try {
      final response = await client!.from('messages').insert({
        'match_id': matchId,
        'sender_id': senderId,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return MessageModel.fromJson(response);
    } catch (e) {
      debugPrint('[SupabaseService] Error sending message: $e');
      return message;
    }
  }

  Future<String?> uploadProfilePhoto(String userId, File photoFile) async {
    if (client == null) return null;

    try {
      final ext = photoFile.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await client!.storage.from('avatars').upload(
            fileName,
            photoFile,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );
      final publicUrl = client!.storage.from('avatars').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('[SupabaseService] Photo upload error: $e');
      return null;
    }
  }

  Future<MatchModel?> fetchMatchById(
    String matchId,
    String currentUserId,
  ) async {
    if (client == null || matchId.isEmpty) return null;

    try {
      final response = await client!
          .from('matches')
          .select('*, user1:profiles!user1_id(*), user2:profiles!user2_id(*)')
          .eq('id', matchId)
          .maybeSingle();

      if (response == null) return null;

      final isUser1Me = response['user1_id'] == currentUserId;
      final otherUserJson = isUser1Me ? response['user2'] : response['user1'];
      if (otherUserJson == null) return null;

      final otherProfile = ProfileModel.fromJson(otherUserJson);
      return MatchModel.fromJson(response, otherProfile);
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching match by id: $e');
      return null;
    }
  }

  RealtimeChannel? subscribeToUserMatches(
    String currentUserId,
    void Function(Map<String, dynamic> record) onMatch,
  ) {
    if (client == null || currentUserId.isEmpty) return null;

    final channelName = 'user_matches_$currentUserId';
    final channel = client!.channel(channelName);
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'matches',
      callback: (payload) {
        final newRecord = payload.newRecord;
        final u1 = newRecord['user1_id'] as String?;
        final u2 = newRecord['user2_id'] as String?;
        if (u1 == currentUserId || u2 == currentUserId) {
          onMatch(newRecord);
        }
      },
    ).subscribe();

    return channel;
  }

  RealtimeChannel? subscribeToMessages(
    String matchId,
    void Function(MessageModel message) onMessage,
  ) {
    if (client == null || matchId.isEmpty) return null;

    final channelName = 'messages_$matchId';
    final channel = client!.channel(channelName);
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'match_id',
        value: matchId,
      ),
      callback: (payload) {
        try {
          final msg = MessageModel.fromJson(payload.newRecord);
          onMessage(msg);
        } catch (e) {
          debugPrint('[SupabaseService] Error parsing realtime message: $e');
        }
      },
    ).subscribe();

    return channel;
  }

  Future<void> unsubscribeChannel(RealtimeChannel? channel) async {
    if (channel != null && client != null) {
      try {
        await client!.removeChannel(channel);
      } catch (e) {
        debugPrint('[SupabaseService] Error removing channel: $e');
      }
    }
  }

  Future<bool> updateProfile(ProfileModel profile) async {
    if (client == null) return false;

    try {
      await client!.from('profiles').upsert(profile.toJson());
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Error updating profile: $e');
      return false;
    }
  }

  Future<bool> deleteCurrentUserAccount() async {
    if (client == null || client?.auth.currentUser == null) return false;
    try {
      final userId = client!.auth.currentUser!.id;
      await client!.from('profiles').delete().eq('id', userId);
      await client!.from('swipes').delete().or('swiper_id.eq.$userId,swiped_id.eq.$userId');
      await client!.auth.signOut();
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Error deleting user account: $e');
      return false;
    }
  }
}
