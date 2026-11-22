class AppConstants {
  AppConstants._();

  static const String appName = 'Crush';
  static const String appTagline = 'Spark genuine connections';

  // Supabase Configuration
  static const String defaultSupabaseUrl =
      'https://kwhklzevjkaqrzrufgyd.supabase.co';
  static const String defaultSupabaseAnonKey =
      'sb_publishable_M5TbaPxagaErnCsO4BOK7w_CcXlxr-7';

  // OAuth & Social Auth Configuration
  static const String authRedirectUri = 'crush://login-callback';
  static const String appleServiceId = 'com.vardhan.crush.app';
  static const String googleWebClientId =
      '678975673146-ms4dt3446ru3ktg6f0g6tplk22mbi38g.apps.googleusercontent.com';
  static const String googleIosClientId =
      '678975673146-51d6djtkg8fg3rhgcv2mjvamceojrhda.apps.googleusercontent.com';
  static const String googleAndroidClientId =
      '678975673146-os51t55cg24ltlscjq3n3137i4itm536.apps.googleusercontent.com';

  // Storage Keys
  static const String prefsUserThemeKey = 'crush_user_theme';

  // Discovery Defaults
  static const double defaultMaxDistanceKm = 50.0;
  static const double minAgeAllowed = 18.0;
  static const double maxAgeAllowed = 65.0;

  // Predefined Interests List
  static const List<String> availableInterests = [
    'Coffee Lover',
    'Foodie',
    'Travel & Adventure',
    'Fitness & Gym',
    'Photography',
    'Music Festivals',
    'Coding & Tech',
    'Dog Lover',
    'Cat Person',
    'Art & Museums',
    'Reading & Books',
    'Hiking & Outdoors',
    'Cooking',
    'Gaming',
    'Yoga & Mindfulness',
    'Movies & Cinephile',
    'Startups & Business',
    'Board Games',
    'Dancing',
    'Wine Tasting',
  ];

  // Icebreaker Prompts
  static const List<String> icebreakers = [
    '👋 Hey! Loved your travel photos. What was your favorite place?',
    '☕ Coffee or cocktails for a first date?',
    '🐶 That dog in your photo is adorable! What\'s their name?',
    '✈️ What is the next dream destination on your bucket list?',
    '🍕 Pineapple on pizza: dealbreaker or delicious?',
  ];
}
