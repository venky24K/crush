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
  bool get useMockMode => false;

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
    int maxAge = 40,
    double maxDistanceKm = 50,
  }) async {
    if (client == null) {
      return [];
    }

    try {
      final List<String> swipedIds = [];
      if (currentUserId.isNotEmpty) {
        final swipedResponse = await client!
            .from('swipes')
            .select('swiped_id')
            .eq('swiper_id', currentUserId);

        swipedIds.addAll((swipedResponse as List)
            .map((row) => row['swiped_id'] as String));
        swipedIds.add(currentUserId);
      }

      var query = client!.from('profiles').select();
      if (currentUserId.isNotEmpty) {
        query = query.neq('id', currentUserId);
        if (swipedIds.length < 50) {
          for (final id in swipedIds) {
            query = query.neq('id', id);
          }
        }
      }

      final response = await query.limit(25);
      return (response as List)
          .map((json) => ProfileModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching discovery: $e');
      return [];
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
      final ext = photoFile.path.split('.').last;
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await client!.storage.from('avatars').upload(fileName, photoFile);
      final publicUrl = client!.storage.from('avatars').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('[SupabaseService] Photo upload error: $e');
      return null;
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
}
