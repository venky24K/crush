# 🔥 Crush - Modern Flutter Dating App

A complete, production-ready, beautifully designed mobile dating application built with **Flutter** and powered by **Supabase** (PostgreSQL, Auth, Storage, and Realtime).

---

## ✨ Features

- **Gesture Card Swiping Deck**: Smooth physics-based card swiping (Swipe Right to Like, Left to Pass, Up to Super Crush).
- **Photo Carousel with Story Bars**: Tap left/right edges on profile cards to browse photos with top story indicator bars.
- **Dynamic Floating Action Buttons**: Rewind, Nope, Super Crush, Like, and Boost with micro-press animations and glow effects.
- **Detailed Profile Sheet**: Expand any card to see full bio, verified badges, job, education, location distance, passions/interests chips, and safety reporting.
- **"It's a Match!" Celebration**: Animated popup with interlocking avatars, glowing heart badge, and instant "Say Hello" CTA.
- **1-on-1 Realtime Chat & Matches**:
  - Horizontal carousel for new matches.
  - Conversation list with last message preview and unread counters.
  - Interactive chat screen with icebreaker suggestion pills, message bubbles, and automatic simulated replies in demo mode.
- **Discovery Filters**: Adjust maximum distance (5–100 km), age range (18–60), and gender preferences.
- **Profile Management**: Upload photos, edit bio, set occupation/school/city, and pick from 20+ passion tags.
- **Zero-Config Demo Mode**: Works immediately out of the box with rich sample profiles and mock chat without requiring a Supabase account upfront!

---

## 🏗️ Project Architecture

```
crush/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart         # Signature romantic gradient & palette
│   │   │   ├── app_constants.dart      # Configuration, interests, icebreakers
│   │   │   └── app_theme.dart          # Material 3 dark theme & typography
│   │   └── services/
│   │       ├── supabase_service.dart   # Supabase client, Auth, Database, Storage
│   │       └── mock_data_service.dart  # Offline mock profiles & chat engine
│   ├── models/
│   │   ├── profile_model.dart          # User profiles (photos, bio, distance)
│   │   ├── match_model.dart            # Mutual match data
│   │   └── message_model.dart          # Chat messages
│   ├── providers/
│   │   ├── auth_provider.dart          # Auth session, current profile, demo toggle
│   │   ├── discovery_provider.dart     # Swiping deck state, undo/rewind, filters
│   │   └── chat_provider.dart          # Matches, realtime message streams
│   ├── ui/
│   │   ├── screens/
│   │   │   ├── auth/                   # Login & multi-step Onboarding
│   │   │   ├── discovery/              # Swipe deck, Filters, Match dialog, Profile sheet
│   │   │   ├── matches/                # Matches list & Realtime Chat
│   │   │   ├── profile/                # User profile & Edit Profile
│   │   │   └── home_navigation_screen.dart # Curved bottom navigation bar
│   │   └── widgets/
│   │       ├── action_button.dart      # Rounded action buttons (Rewind/Nope/Like)
│   │       ├── interest_chip.dart      # Interactive interest tags
│   │       └── swipe_card.dart         # Gesture card with photo switching
│   └── main.dart                       # App entry point & AuthGate
├── supabase/
│   └── schema.sql                      # Complete SQL migrations, triggers & RLS
└── pubspec.yaml
```

---

## 🚀 Quick Start (Instant Demo Mode)

You can run the app immediately on your simulator, device, or desktop without any backend setup:

```bash
# 1. Get dependencies
flutter pub get

# 2. Run on your preferred target (iOS simulator, Android emulator, macOS, or Chrome)
flutter run
```

When the app opens:
1. Tap **"Explore in Demo Mode"** (or sign in with pre-filled test credentials).
2. Enjoy swiping cards, tapping photos, testing rewinds, triggering matches, and chatting in real-time!

---

## ⚡ Connecting to Live Supabase Backend

When you are ready to connect to your live Supabase cloud database:

### 1. Create a Supabase Project
1. Go to [supabase.com](https://supabase.com) and create a free project.
2. In the Supabase Dashboard, go to **Project Settings -> API** and copy:
   - **Project URL**
   - **anon / public key**

### 2. Run Database Migrations
1. In the Supabase Dashboard, open the **SQL Editor**.
2. Open the file `supabase/schema.sql` located in this project.
3. Paste its contents into the SQL Editor and click **Run**.
   - This sets up:
     - `profiles` table with Row Level Security (RLS)
     - `swipes` table with unique constraint on `(swiper_id, swiped_id)`
     - `matches` table
     - Automatic database trigger function `handle_swipe_match()`: detects mutual likes and automatically creates a match!
     - `messages` table with Realtime publication enabled
     - Storage bucket (`avatars`) with public read policies

### 3. Add Your Credentials in the App
Open `lib/core/constants/app_constants.dart` and update:

```dart
static const String defaultSupabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
static const String defaultSupabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

Now launch the app, toggle off Demo Mode in the Profile settings, and the app will authenticate against your live Supabase database!

---

## 📱 Testing & Verification

Run the test suite:
```bash
flutter test
```

Run static code analysis:
```bash
flutter analyze
```
*(Both pass with 0 warnings/errors!)*
