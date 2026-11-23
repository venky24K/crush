import 'package:crush/core/constants/profile_options.dart';

/// Editable sections of a profile. The profile tab chips deep-link to these,
/// and [ProfileModel.stateOf] derives completion state from them.
enum ProfileSection {
  photos,
  about,
  prompts,
  basics,
  lifestyle,
  goal,
  career,
  education,
  height,
  livingIn,
  interests,
}

enum SectionState { empty, partial, complete }

class PromptAnswer {
  const PromptAnswer({required this.prompt, required this.answer});

  final String prompt;
  final String answer;

  factory PromptAnswer.fromJson(Map<String, dynamic> json) => PromptAnswer(
        prompt: json['prompt'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'prompt': prompt, 'answer': answer};
}

class ProfileModel {
  final String id;
  final String email;
  final String fullName;
  final DateTime birthDate;
  final String gender;
  final List<String> lookingFor;
  final String bio;
  final String occupation;
  final String school;
  final List<String> photos;
  final List<String> interests;
  final double? latitude;
  final double? longitude;
  final String city; // shown as "Living in"
  final double distanceKm;
  final bool isVerified;

  // New profile fields. basics/lifestyle are keyed by ProfileFieldDef.key and
  // stored as jsonb; values are the plain option strings.
  final int? heightCm;
  final String? relationshipGoal;
  final Map<String, String> basics;
  final Map<String, String> lifestyle;
  final List<PromptAnswer> prompts;

  // Discovery preferences. These are settings, not profile, and should move
  // to a settings model when the settings screen gets built. Left here so
  // existing discovery and auth code keeps working.
  final int minAgePreference;
  final int maxAgePreference;
  final int maxDistanceKm;

  ProfileModel({
    required this.id,
    this.email = '',
    required this.fullName,
    required this.birthDate,
    required this.gender,
    this.lookingFor = const ['female'],
    this.bio = '',
    this.occupation = '',
    this.school = '',
    this.photos = const [],
    this.interests = const [],
    this.latitude,
    this.longitude,
    this.city = '',
    this.distanceKm = 0.0,
    this.isVerified = false,
    this.heightCm,
    this.relationshipGoal,
    this.basics = const {},
    this.lifestyle = const {},
    this.prompts = const [],
    this.minAgePreference = 18,
    this.maxAgePreference = 40,
    this.maxDistanceKm = 50,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String get primaryPhoto {
    if (photos.isNotEmpty) return photos.first;
    return '';
  }

  // ---------------------------------------------------------------------------
  // Completion (derived, never stored)
  // ---------------------------------------------------------------------------

  int get basicsFilled => ProfileOptions.basics
      .where((d) => (basics[d.key] ?? '').isNotEmpty)
      .length;

  int get lifestyleFilled => ProfileOptions.lifestyle
      .where((d) => (lifestyle[d.key] ?? '').isNotEmpty)
      .length;

  static SectionState _flag(bool filled) =>
      filled ? SectionState.complete : SectionState.empty;

  static SectionState _group(int filled, int total) {
    if (filled == 0) return SectionState.empty;
    return filled >= total ? SectionState.complete : SectionState.partial;
  }

  SectionState stateOf(ProfileSection section) {
    switch (section) {
      case ProfileSection.photos:
        if (photos.isEmpty) return SectionState.empty;
        return photos.length < 2 ? SectionState.partial : SectionState.complete;
      case ProfileSection.about:
        return _flag(bio.trim().isNotEmpty);
      case ProfileSection.prompts:
        return _flag(prompts.isNotEmpty);
      case ProfileSection.basics:
        return _group(basicsFilled, ProfileOptions.basics.length);
      case ProfileSection.lifestyle:
        return _group(lifestyleFilled, ProfileOptions.lifestyle.length);
      case ProfileSection.goal:
        return _flag(relationshipGoal != null);
      case ProfileSection.career:
        return _flag(occupation.trim().isNotEmpty);
      case ProfileSection.education:
        return _flag(school.trim().isNotEmpty);
      case ProfileSection.height:
        return _flag(heightCm != null);
      case ProfileSection.livingIn:
        return _flag(city.trim().isNotEmpty);
      case ProfileSection.interests:
        if (interests.isEmpty) return SectionState.empty;
        return interests.length < ProfileOptions.minInterests
            ? SectionState.partial
            : SectionState.complete;
    }
  }

  static const Map<ProfileSection, int> _weights = {
    ProfileSection.photos: 3,
    ProfileSection.about: 2,
    ProfileSection.interests: 2,
  };

  /// 0.0 to 1.0. Photos, bio and interests count more; the rest weigh 1.
  double get completeness {
    var earned = 0.0;
    var total = 0.0;
    for (final s in ProfileSection.values) {
      final w = (_weights[s] ?? 1).toDouble();
      total += w;
      earned += switch (stateOf(s)) {
        SectionState.complete => w,
        SectionState.partial => w / 2,
        SectionState.empty => 0.0,
      };
    }
    return earned / total;
  }

  static const List<ProfileSection> _priority = [
    ProfileSection.photos,
    ProfileSection.about,
    ProfileSection.interests,
    ProfileSection.goal,
    ProfileSection.basics,
    ProfileSection.lifestyle,
    ProfileSection.career,
    ProfileSection.education,
    ProfileSection.height,
    ProfileSection.livingIn,
    ProfileSection.prompts,
  ];

  /// First section worth nudging the user toward, or null when complete.
  ProfileSection? get nextIncomplete {
    for (final s in _priority) {
      if (stateOf(s) != SectionState.complete) return s;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  static Map<String, String> _stringMap(dynamic raw) {
    if (raw is! Map) return {};
    return {
      for (final e in raw.entries)
        if (e.value != null) e.key.toString(): e.value.toString(),
    };
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Anonymous',
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'].toString()) ??
              DateTime(2000, 1, 1)
          : DateTime(2000, 1, 1),
      gender: json['gender'] as String? ?? 'other',
      lookingFor: (json['looking_for'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['female'],
      bio: json['bio'] as String? ?? '',
      occupation: json['occupation'] as String? ?? '',
      school: json['school'] as String? ?? '',
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      city: json['city'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 5.0,
      isVerified: json['is_verified'] as bool? ?? false,
      heightCm: (json['height_cm'] as num?)?.toInt(),
      relationshipGoal: json['relationship_goal'] as String?,
      basics: _stringMap(json['basics']),
      lifestyle: _stringMap(json['lifestyle']),
      prompts: (json['prompts'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => PromptAnswer.fromJson(Map<String, dynamic>.from(e)))
              .where((p) => p.prompt.isNotEmpty && p.answer.isNotEmpty)
              .toList() ??
          [],
      minAgePreference: (json['min_age_preference'] as num?)?.toInt() ?? 18,
      maxAgePreference: (json['max_age_preference'] as num?)?.toInt() ?? 50,
      maxDistanceKm: (json['max_distance_km'] as num?)?.toInt() ?? 50,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'birth_date': birthDate.toIso8601String().split('T')[0],
      'gender': gender,
      'looking_for': lookingFor,
      'bio': bio,
      'occupation': occupation,
      'school': school,
      'photos': photos,
      'interests': interests,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'is_verified': isVerified,
      'height_cm': heightCm,
      'relationship_goal': relationshipGoal,
      'basics': basics,
      'lifestyle': lifestyle,
      'prompts': prompts.map((p) => p.toJson()).toList(),
      'min_age_preference': minAgePreference,
      'max_age_preference': maxAgePreference,
      'max_distance_km': maxDistanceKm,
    };
  }

  /// [clearHeight] / [clearRelationshipGoal] exist because `x ?? this.x`
  /// can't distinguish "leave unchanged" from "set to null".
  ProfileModel copyWith({
    String? id,
    String? email,
    String? fullName,
    DateTime? birthDate,
    String? gender,
    List<String>? lookingFor,
    String? bio,
    String? occupation,
    String? school,
    List<String>? photos,
    List<String>? interests,
    double? latitude,
    double? longitude,
    String? city,
    double? distanceKm,
    bool? isVerified,
    int? heightCm,
    bool clearHeight = false,
    String? relationshipGoal,
    bool clearRelationshipGoal = false,
    Map<String, String>? basics,
    Map<String, String>? lifestyle,
    List<PromptAnswer>? prompts,
    int? minAgePreference,
    int? maxAgePreference,
    int? maxDistanceKm,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      bio: bio ?? this.bio,
      occupation: occupation ?? this.occupation,
      school: school ?? this.school,
      photos: photos ?? this.photos,
      interests: interests ?? this.interests,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      distanceKm: distanceKm ?? this.distanceKm,
      isVerified: isVerified ?? this.isVerified,
      heightCm: clearHeight ? null : (heightCm ?? this.heightCm),
      relationshipGoal: clearRelationshipGoal
          ? null
          : (relationshipGoal ?? this.relationshipGoal),
      basics: basics ?? this.basics,
      lifestyle: lifestyle ?? this.lifestyle,
      prompts: prompts ?? this.prompts,
      minAgePreference: minAgePreference ?? this.minAgePreference,
      maxAgePreference: maxAgePreference ?? this.maxAgePreference,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    );
  }
}
