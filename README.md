# 🔥 Crush - Modern Flutter Dating App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL%20%7C%20Auth%20%7C%20Storage-3ECF8E?logo=supabase&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

**Crush** is a production-ready, beautifully designed mobile dating application built with **Flutter** and powered by **Supabase**. Featuring fluid gesture card swiping, photo story carousels, instant mutual match triggers, and real-time chat.

[Features](#-features) • [Quick Start](#-quick-start) • [Supabase Setup](#-live-supabase-setup) • [Architecture](#-project-architecture) • [Roadmap](ROADMAP.md)

</div>

---

## ✨ Features

### 🎴 Discovery & Card Swiping
- **Gesture Swiper**: Smooth physics-driven swipe gestures (Right = Like, Left = Pass, Up = Super Crush).
- **Photo Carousel with Story Bars**: Tap the left or right halves of cards to browse photos with top indicator bars (similar to Instagram/Tinder).
- **Action Floating Buttons**: Rewind (undo last swipe), Dislike, Super Crush, Like, and Boost with micro-press physics.
- **Detailed Profile Sheet**: Swipe up or tap info to view bio, verified badges, job, education, distance, and 20+ passion tags.
- **Discovery Filters**: Filter potential matches by maximum distance (5–100 km), age range (18–60), and gender preferences.

### 💖 Matching & Celebration
- **Automatic Mutual Match Trigger**: PostgreSQL database function automatically detects when two users like each other and instantly creates a match.
- **Celebration Modal**: Animated popup with interlocking avatars, pulsing heart badge, and immediate CTAs ("Say Hello" or "Keep Swiping").

### 💬 Realtime Messaging & Icebreakers
- **New Matches Stories**: Horizontal avatar reel highlighting recent mutual matches.
- **Conversations List**: Real-time previews of last messages, timestamps, and unread counters.
- **1-on-1 Chat Screen**: Custom message bubbles with sender colors, timestamps, and active status.
- **Icebreaker Suggestion Pills**: Tap curated icebreaker prompts to immediately send engaging openers.
- **Auto-Reply Simulator**: In demo mode, matches automatically reply after 1.5 seconds for instant testing.

### 👤 Profile & Customization
- **Multi-Photo Manager**: Upload and rearrange up to 6 profile photos with a primary photo badge.
- **About Me & Essentials**: Edit bio, occupation, school, and current city.
- **Passion Tags**: Interactive chip selector for 20+ lifestyle interests (Coffee Lover, Coding, Hiking, Bouldering, etc.).
- **Dual Mode**: Seamlessly switch between **Demo Mode** (offline mock data) and **Live Supabase** directly from settings.

---

## 🏗️ Project Architecture

```
crush/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart         # Signature rose/coral romantic gradients
│   │   │   ├── app_constants.dart      # Supabase URL/keys, defaults, interests
│   │   │   └── app_theme.dart          # Material 3 dark theme & typography
│   │   └── services/
│   │       ├── supabase_service.dart   # Supabase client, Auth, Database, Storage
│   │       └── mock_data_service.dart  # Offline mock profiles & chat engine
│   ├── models/
│   │   ├── profile_model.dart          # User profiles (photos, bio, distance)
│   │   ├── match_model.dart            # Mutual match structure
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
│   ├── schema.sql                      # Idempotent database schema, triggers & RLS
│   └── seed.sql                        # Sample discovery profiles for testing
├── .env                                # Local environment credentials
├── ROADMAP.md                          # Full future milestone roadmap
└── pubspec.yaml
```

---

## 🚀 Quick Start

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.13+ / 3.47+)
- Xcode (for iOS simulator/device) or Android Studio (for Android emulator)

### 2. Install & Run
```bash
# Clone the repository
git clone https://github.com/your-username/crush.git
cd crush

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## ⚡ Live Supabase Setup

Your project already has Supabase configured. If setting up a fresh project:

1. **Create a Supabase Project** at [supabase.com](https://supabase.com).
2. **Apply Database Schema**:
   - Open **SQL Editor** in your Supabase dashboard.
   - Paste the contents of [supabase/schema.sql](supabase/schema.sql) and click **Run**.
   - This sets up tables (`profiles`, `swipes`, `matches`, `messages`), RLS policies, match trigger (`handle_swipe_match`), and the `avatars` storage bucket.
3. **Seed Test Profiles**:
   - Paste the contents of [supabase/seed.sql](supabase/seed.sql) into the SQL Editor and click **Run**.
4. **Update Credentials**:
   - Set your keys in `.env` and `lib/core/constants/app_constants.dart`:
     ```dart
     static const String defaultSupabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
     static const String defaultSupabaseAnonKey = 'YOUR_PUBLISHABLE_KEY';
     ```

---

## 🧪 Testing & Verification

```bash
# Run unit and widget tests
flutter test

# Run static code analysis
flutter analyze
```

Both pass with **0 errors and 0 warnings**.

---

## 🗺️ Roadmap & Future Milestones

See the complete **[ROADMAP.md](ROADMAP.md)** for detailed plans on:
- **Phase 2**: Apple/Google OAuth, Phone OTP Auth, Live PostGIS GPS Queries, and Push Notifications (FCM/APNs).
- **Phase 3**: In-App Purchases & Subscriptions (Crush Gold & Platinum via RevenueCat).
- **Phase 4**: Selfie Liveness Verification, AI Conversation Starters (Gemini API), and In-App Video Dates.

---

## 📄 License

This project is licensed under the MIT License.
