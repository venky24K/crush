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
  final String city;
  final double distanceKm;
  final bool isVerified;
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
    return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80';
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
      minAgePreference: json['min_age_preference'] as int? ?? 18,
      maxAgePreference: json['max_age_preference'] as int? ?? 40,
      maxDistanceKm: json['max_distance_km'] as int? ?? 50,
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
      'min_age_preference': minAgePreference,
      'max_age_preference': maxAgePreference,
      'max_distance_km': maxDistanceKm,
    };
  }

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
      minAgePreference: minAgePreference ?? this.minAgePreference,
      maxAgePreference: maxAgePreference ?? this.maxAgePreference,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    );
  }
}
