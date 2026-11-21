import 'profile_model.dart';

class MatchModel {
  final String id;
  final String matchedUserId;
  final ProfileModel user;
  final DateTime createdAt;
  final String lastMessage;
  final DateTime lastMessageAt;
  final bool hasUnread;

  MatchModel({
    required this.id,
    required this.matchedUserId,
    required this.user,
    required this.createdAt,
    this.lastMessage = '',
    required this.lastMessageAt,
    this.hasUnread = false,
  });

  factory MatchModel.fromJson(
    Map<String, dynamic> json,
    ProfileModel matchedProfile,
  ) {
    return MatchModel(
      id: json['id'] as String? ?? '',
      matchedUserId: matchedProfile.id,
      user: matchedProfile,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastMessage: json['last_message'] as String? ?? 'You matched!',
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      hasUnread: json['has_unread'] as bool? ?? false,
    );
  }

  MatchModel copyWith({
    String? id,
    String? matchedUserId,
    ProfileModel? user,
    DateTime? createdAt,
    String? lastMessage,
    DateTime? lastMessageAt,
    bool? hasUnread,
  }) {
    return MatchModel(
      id: id ?? this.id,
      matchedUserId: matchedUserId ?? this.matchedUserId,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      hasUnread: hasUnread ?? this.hasUnread,
    );
  }
}
