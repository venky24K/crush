import '../../models/profile_model.dart';
import '../../models/match_model.dart';
import '../../models/message_model.dart';

class MockDataService {
  MockDataService._();

  static final ProfileModel currentUser = ProfileModel(
    id: 'user_current_me',
    email: 'alex@crush.app',
    fullName: 'Alex Rivera',
    birthDate: DateTime(1998, 5, 14),
    gender: 'male',
    lookingFor: ['female'],
    bio: 'Architect by day, amateur chef & vinyl collector by night. Looking for someone to explore hidden coffee spots and art galleries with ☕✨',
    occupation: 'Architect & Designer',
    school: 'Columbia University',
    city: 'San Francisco, CA',
    distanceKm: 0,
    isVerified: true,
    interests: ['Coffee Lover', 'Design', 'Vinyl Records', 'Hiking', 'Cooking'],
    photos: [
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=800&q=80',
    ],
  );

  static final List<ProfileModel> discoveryProfiles = [
    ProfileModel(
      id: 'profile_1',
      fullName: 'Maya Lin',
      birthDate: DateTime(1999, 8, 22), // 25
      gender: 'female',
      lookingFor: ['male'],
      bio: 'Photographer traveling the world with a 35mm film camera. Tell me your top 3 songs and I\'ll guess your favorite midnight snack 🎧🎞️',
      occupation: 'Documentary Photographer',
      school: 'RISD',
      city: 'North Beach, SF',
      distanceKm: 3.2,
      isVerified: true,
      interests: ['Photography', 'Music Festivals', 'Travel & Adventure', 'Art & Museums', 'Coffee Lover'],
      photos: [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80',
      ],
    ),
    ProfileModel(
      id: 'profile_2',
      fullName: 'Chloe Dupont',
      birthDate: DateTime(1997, 3, 10), // 27
      gender: 'female',
      lookingFor: ['male'],
      bio: 'French expat in SF. Founder of a plant-based bakery 🌱🥐. Love sunset runs across Golden Gate and spontaneous weekend getaways.',
      occupation: 'Pastry Chef & Founder',
      school: 'Le Cordon Bleu Paris',
      city: 'Marina District, SF',
      distanceKm: 4.8,
      isVerified: true,
      interests: ['Cooking', 'Foodie', 'Fitness & Gym', 'Wine Tasting', 'Dog Lover'],
      photos: [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=800&q=80',
      ],
    ),
    ProfileModel(
      id: 'profile_3',
      fullName: 'Elena Rostova',
      birthDate: DateTime(2000, 11, 4), // 24
      gender: 'female',
      lookingFor: ['male'],
      bio: 'AI researcher who spends too much time debating sci-fi paradoxes. Also teach salsa on Thursday nights 💃 Let\'s grab matcha!',
      occupation: 'AI Research Scientist',
      school: 'Stanford',
      city: 'Palo Alto / SF',
      distanceKm: 8.5,
      isVerified: true,
      interests: ['Coding & Tech', 'Dancing', 'Reading & Books', 'Coffee Lover', 'Startups & Business'],
      photos: [
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?auto=format&fit=crop&w=800&q=80',
      ],
    ),
    ProfileModel(
      id: 'profile_4',
      fullName: 'Sarah Chen',
      birthDate: DateTime(1998, 7, 19), // 26
      gender: 'female',
      lookingFor: ['male'],
      bio: 'Ceramic artist & indie bookstore addict. Golden retriever mom (his name is Mochi 🐾). Looking for my concert buddy!',
      occupation: 'Ceramicist & Illustrator',
      school: 'CalArts',
      city: 'Mission District, SF',
      distanceKm: 2.1,
      isVerified: false,
      interests: ['Dog Lover', 'Art & Museums', 'Music Festivals', 'Hiking & Outdoors', 'Board Games'],
      photos: [
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
      ],
    ),
    ProfileModel(
      id: 'profile_5',
      fullName: 'Zara Patel',
      birthDate: DateTime(1996, 12, 1), // 28
      gender: 'female',
      lookingFor: ['male'],
      bio: 'Bouldering, hot yoga, and hunting down the best street tacos in the bay 🌮 Always down for a board game tournament or comedy show.',
      occupation: 'Product Manager',
      school: 'UC Berkeley',
      city: 'Hayes Valley, SF',
      distanceKm: 5.6,
      isVerified: true,
      interests: ['Fitness & Gym', 'Yoga & Mindfulness', 'Foodie', 'Board Games', 'Travel & Adventure'],
      photos: [
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80',
      ],
    ),
  ];

  static List<MatchModel> getInitialMatches() {
    return [
      MatchModel(
        id: 'match_1',
        matchedUserId: discoveryProfiles[0].id,
        user: discoveryProfiles[0],
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        lastMessage: 'I loved that coffee place you mentioned!',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 12)),
        hasUnread: true,
      ),
      MatchModel(
        id: 'match_2',
        matchedUserId: discoveryProfiles[1].id,
        user: discoveryProfiles[1],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        lastMessage: 'Let\'s do sunset drinks this Friday? 🥂',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
        hasUnread: false,
      ),
      MatchModel(
        id: 'match_3',
        matchedUserId: discoveryProfiles[2].id,
        user: discoveryProfiles[2],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        lastMessage: 'Haha definitely! See you then',
        lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
        hasUnread: false,
      ),
    ];
  }

  static List<MessageModel> getMockMessagesForMatch(String matchId) {
    final now = DateTime.now();
    return [
      MessageModel(
        id: 'm1',
        matchId: matchId,
        senderId: 'other_user',
        content: 'Hey Alex! Your profile has such great vibes ✨',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 30)),
        isRead: true,
      ),
      MessageModel(
        id: 'm2',
        matchId: matchId,
        senderId: currentUser.id,
        content: 'Hey Maya! Thanks so much. Loved your film photography shots!',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 15)),
        isRead: true,
      ),
      MessageModel(
        id: 'm3',
        matchId: matchId,
        senderId: 'other_user',
        content: 'Thank you! I shot those during a road trip to Big Sur last month.',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
        isRead: true,
      ),
      MessageModel(
        id: 'm4',
        matchId: matchId,
        senderId: currentUser.id,
        content: 'Big Sur is stunning! Have you tried the coffee shop near Bixby Bridge?',
        createdAt: now.subtract(const Duration(minutes: 40)),
        isRead: true,
      ),
      MessageModel(
        id: 'm5',
        matchId: matchId,
        senderId: 'other_user',
        content: 'I loved that coffee place you mentioned! We should go together next time ☕',
        createdAt: now.subtract(const Duration(minutes: 12)),
        isRead: false,
      ),
    ];
  }
}
