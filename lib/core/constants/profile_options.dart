/// Static catalog for the structured profile fields.
///
/// Selections are stored as plain strings (jsonb in Supabase), so renaming or
/// adding an option never breaks old rows: an unknown value just renders as-is.
class ProfileFieldDef {
  const ProfileFieldDef(this.key, this.label, this.options);

  final String key;
  final String label;
  final List<String> options;
}

abstract final class ProfileOptions {
  static const int maxInterests = 5;
  static const int minInterests = 3; // threshold for "complete"
  static const int maxPrompts = 3;

  static const goal = ProfileFieldDef('relationship_goal', 'Looking for', [
    'Long-term partner',
    'Long-term, open to short',
    'Short-term, open to long',
    'Short-term fun',
    'New friends',
    'Still figuring it out',
  ]);

  static const basics = <ProfileFieldDef>[
    ProfileFieldDef('zodiac', 'Zodiac', [
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces',
    ]),
    ProfileFieldDef('education_level', 'Education level', [
      'High school',
      'Undergraduate',
      'Postgraduate',
      'Doctorate',
      'Trade school',
    ]),
    ProfileFieldDef('family_plans', 'Family plans', [
      'Want kids',
      "Don't want kids",
      'Have kids and want more',
      "Have kids and don't want more",
      'Not sure yet',
    ]),
    ProfileFieldDef('communication_style', 'Communication style', [
      'Big time texter',
      'Phone caller',
      'Video chatter',
      'Bad texter',
      'Better in person',
    ]),
    ProfileFieldDef('love_style', 'Love style', [
      'Thoughtful gestures',
      'Presents',
      'Touch',
      'Compliments',
      'Time together',
    ]),
  ];

  static const lifestyle = <ProfileFieldDef>[
    ProfileFieldDef('drinking', 'Drinking', [
      'Not for me',
      'Sober',
      'Special occasions',
      'Socially on weekends',
      'Most nights',
    ]),
    ProfileFieldDef('smoking', 'Smoking', [
      'Non-smoker',
      'Social smoker',
      'Smoker',
      'Trying to quit',
    ]),
    ProfileFieldDef('workout', 'Workout', [
      'Every day',
      'Often',
      'Sometimes',
      'Never',
    ]),
    ProfileFieldDef('pets', 'Pets', [
      'Dog',
      'Cat',
      'Dog and cat',
      'Other pets',
      'No pets',
      'Want a pet',
    ]),
  ];

  static const prompts = <String>[
    'A perfect Sunday looks like',
    'Two truths and a lie',
    'The way to win me over is',
    'My most controversial opinion is',
    'I geek out on',
    'Together we could',
  ];
}
