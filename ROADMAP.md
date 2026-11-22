# 🗺️ Crush - Product & Engineering Roadmap

This roadmap outlines completed milestones, current capabilities, and future vision for **Crush** — from core swipe mechanics and native authentication to page-by-page UX polish, real-time messaging, AI safety, and global monetization.

---

## 🧭 Milestone Overview

```mermaid
flowchart LR
    A["Phase 1: Core MVP & Backend (Done)"] --> B["Phase 1.5: Brand & Light Theme (Done)"]
    B --> C["Phase 2: Native Auth, Storage & TestFlight (Done)"]
    C --> D["Phase 3: Page-by-Page UX Polish (Current)"]
    D --> E["Phase 4: Notifications & Geolocation"]
    E --> F["Phase 5: Subscriptions & Monetization"]
    F --> G["Phase 6: AI Matching & Trust Safety"]
```

---

## ✅ Phase 1: Core MVP & Foundation *(Completed)*

- [x] **Flutter Architecture & Clean State Management**
  - Modular clean-architecture project structure (`core`, `models`, `providers`, `ui`, `services`).
  - Provider state architecture separating Auth, Discovery, and Chat concerns.
  - Live Supabase connection with graceful fallback handling.
- [x] **Gesture Card Swiping Deck**
  - Card swiper with physics-driven gestures (Right: Like, Left: Pass, Up: Super Crush).
  - Multi-photo carousel on cards with story progress indicators and tap edge navigation.
  - Floating action buttons: Rewind, Dislike, Super Crush, Like, and Boost.
- [x] **Live Supabase Backend & Database Schema**
  - PostgreSQL schema with Row-Level Security (RLS) on `profiles`, `swipes`, `matches`, and `messages`.
  - Database triggers for reciprocal match creation and message timestamp updates.
  - Realtime publication stream enabled for live chat and match notifications.
- [x] **Discovery Filters & Profile Detail Sheet**
  - Dynamic discovery filters: Distance slider (5–100 km), Age range slider (18–60), and Gender preference.
  - Profile detail modal bottom sheet with photo gallery, bio, work, school, and passion chips.

---

## ✅ Phase 1.5: Brand Identity, High-Contrast UI & Performance *(Completed)*

- [x] **Brand Identity & Asset Suite**
  - Custom **crush** logo typography featuring a soft coral heart nested inside the `"u"`.
  - Master high-res transparent wordmark (`logo_wordmark.png`).
  - Full suite of iOS App Icons (15 resolutions in `AppIcon.appiconset`) and Android mipmap launcher icons.
- [x] **Flutter Native Splash Screen**
  - Integrated `flutter_native_splash` for instant native app launch on iOS and Android.
  - Branded launch screen on Warm Ivory (`#FFF8F2`) background with centered wordmark.
- [x] **Crisp High-Contrast Light Theme Overhaul**
  - Switched to clean, modern, high-contrast light theme:
    - **Background**: Pure `#FFFFFF` for crisp readability.
    - **Containers & Search**: `#F3F4F6` with subtle `#E5E7EB` borders.
    - **Typography**: Deep Charcoal `#111827` (Headings) and Slate Grey `#4B5563` (Subtitles/Bios).
    - **Brand Accent**: Punchy Peach-Coral `#FF5364` on action buttons, badges, and active tabs.
- [x] **60 FPS Swiping & Rendering Optimization**
  - Eliminated swipe stutter; granular `Selector` rebuild scopes for card deck state.
  - Added `RepaintBoundary` wrappers around swipe cards and app bar components.
  - Fixed Material layering and invisible ink splash assertions across list tiles and bottom sheets.

---

## ✅ Phase 2: Production Auth, Storage, Store Compliance & TestFlight *(Completed)*

- [x] **Native Authentication Gateways**
  - **Sign in with Apple**: Native iOS bottom sheet with Face ID / Touch ID, SHA-256 cryptographic nonce hashing, and user metadata capture.
  - **Sign in with Google**: Native Google Sign-In SDK (1-tap sheet) with in-app browser OAuth fallback.
  - **Reactive 3-State Auth Machine**: Clean separation between Unauthenticated &rarr; Needs Onboarding &rarr; Fully Authenticated (`HomeNavigationScreen`).
- [x] **9-Step Guided Onboarding Flow**
  - First Name identity gate (prevents impersonation).
  - Cupertino date wheel with strict 18+ legal age verification check.
  - Gender identity & dating preference selection.
  - Relationship intentions / dating goals with punchy tags.
  - 6-slot photo grid with primary avatar badge.
  - Searchable interest chip selector (5+ required).
  - Location setup with automatic pre-fill.
  - Bio, occupation, and school configuration.
  - 4-point community safety pledge.
- [x] **Universal Photo Engine (`CrushImage` & `crushImageProvider`)**
  - Dual support for local device file paths (`/var/mobile/...`, `file://`) and remote Supabase CDN URLs (`https://...`).
  - Elimination of broken image red "X" errors with branded loading shimmers and fallback avatars.
  - Interactive photo picker on Edit Profile (Gallery, Camera, Sample photo).
- [x] **Cloud Storage & Database Infrastructure**
  - Supabase Storage `avatars` bucket configured, verified public, and connected to upload pipelines.
  - Realtime enabled on `messages` table for instant live message delivery.
- [x] **App Store & Google Play Policy Compliance**
  - Apple Guideline 5.1.1(v) permanent in-app **Account Deletion** flow with confirmation dialog.
  - Apple Guideline 1.2 **Block & Report User** safety controls in chat & profile details.
  - iOS `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, and `ITSAppUsesNonExemptEncryption = false`.
  - Android release permissions (`INTERNET`, `CAMERA`, `READ_MEDIA_IMAGES`).
  - Hosted legal pages deployed on GitHub Pages:
    - Privacy Policy: `https://venky24k.github.io/crush/privacy.html`
    - Terms of Service: `https://venky24k.github.io/crush/terms.html`
    - Landing Page: `https://venky24k.github.io/crush/`
  - In-app interactive legal bottom sheet on login screen.
- [x] **Production iOS Release & TestFlight**
  - Production `.ipa` built, code-signed, and delivered via Apple Transporter.
  - App Store Connect app record registered (`com.vardhan.crush.app`).
  - App encryption export compliance verified & build live on **Apple TestFlight**.

---

## 🎨 Phase 3: Page-by-Page UX Polish & Micro-Interactions *(Current Sprint)*

This phase elevates Crush from a working prototype into a consumer-grade dating app with fluid physics, haptics, and delight across each individual screen:

### 🃏 3.1 Discovery & Swipe Card Screen
- [ ] **Instagram-Style Story Photo Navigation**: Tap left 30% of card for previous photo, tap right 70% for next photo, with top progress bars.
- [ ] **Swipe Haptic Feedback**: Light haptic tick on drag threshold; crisp tactile feedback on Like, Nope, and Super Like (`HapticFeedback.mediumImpact()`).
- [ ] **Rewind / Undo Action**: Functional rewind restoring the previously swiped card back to the top of the deck.
- [ ] **Super Like Particle Burst**: Animated gold/blue star burst with micro-confetti on Super Like.
- [ ] **Match Celebration Screen**: Synchronized dual-photo pulse animation with instant "Send a message" input field.

### 📝 3.2 Onboarding Flow (9 Steps)
- [ ] **Hinge-Style Personality Prompts**: Pick and answer 2–3 fun prompt cards (*"A typical Sunday for me looks like...", "My biggest green flag is..."*).
- [ ] **Photo Quality Validator & Drag Reorder**: Drag-and-drop to reorder photo hierarchy; minimum resolution hints.
- [ ] **Animated Step Indicator**: Smooth sliding progress bar with percentage and step transitions.

### 💬 3.3 Matches & Real-Time Chat
- [ ] **Interactive Conversation Starters**: Tappable icebreaker question pills in empty chats that auto-fill the input field.
- [ ] **Online Activity Indicators & Read Receipts**: Real-time "Active now" badges and `✓✓` read receipts on delivered messages.
- [ ] **In-Chat Photo Sharing**: Camera and gallery attachments directly inside private conversations.
- [ ] **Typing Indicator Animation**: Animated 3-dot bubble showing when the other person is typing.

### 👤 3.4 User Profile & Edit Suite
- [ ] **"Preview Profile" Mode**: 1-tap preview toggle allowing users to view their profile exactly as prospective matches see it.
- [ ] **Profile Completeness Gauge**: Circular or bar meter (*"85% complete — add 2 more passions to get 3x matches"*).
- [ ] **Discovery Preference Controls**: Age range dual-slider and distance radius slider saving directly to Supabase profile preferences.

### 🔐 3.5 Login & Welcome Gateway
- [ ] **Ambient Motion Background**: Subtle floating coral/warm ivory gradient or gentle heart particles.
- [ ] **Spring Micro-Interactions**: Tactile button press bounce on Apple, Google, and Email sign-in buttons.

---

## 📍 Phase 4: Push Notifications & Geolocation *(Next Up)*

- [ ] **Push Notifications (APNs / FCM)**
  - Firebase Cloud Messaging integration for iOS (APNs) and Android.
  - Triggered push alerts on:
    - Mutual match (*"It's a Match! Say hello to [Name]"*).
    - New chat message.
    - Super Like received.
- [ ] **Live Geolocation & PostGIS Distance Queries**
  - Device GPS coordinate capture via `geolocator` with permission dialogs.
  - PostgreSQL PostGIS queries (`ST_DWithin`, `ST_DistanceSphere`) to calculate exact distances and filter profiles dynamically within the user's selected radius.
- [ ] **Voice Notes & Audio in Chat**
  - In-chat voice recording and playback with interactive waveform visualizers.

---

## 💎 Phase 5: Premium Features & Monetization *(Q2)*

- [ ] **RevenueCat In-App Purchases (IAP)**
  - Integration with Apple StoreKit 2 and Google Play Billing via RevenueCat.
  - Paywall screens with introductory trials and subscription tiers.
- [ ] **Crush Gold Subscription**
  - **"See Who Liked You"**: Grid view displaying users who already swiped right on your profile.
  - **Unlimited Swipes**: Remove the standard 50 likes/12-hour limit.
  - **5 Free Super Crushes Daily**.
  - **Passport Mode**: Travel to any city in the world to browse and match prior to visiting.
  - **Unlimited Rewinds**: Undo any accidental pass.
- [ ] **Crush Platinum Subscription**
  - **Priority Likes**: Card placed at the top of the deck for users you like.
  - **Note with Super Crush**: Send a personalized note before matching.
- [ ] **Consumable Packs**
  - **Crush Boost**: 30-minute top profile placement in your local area (up to 10x visibility).
  - **Super Crush Bundles**: Packs of 5, 15, or 30 Super Crushes.

---

## 🛡️ Phase 6: Trust, Safety & AI *(Q3)*

- [ ] **Selfie Photo Verification**
  - On-device liveness and pose verification (e.g. smile, head tilt) using ML Kit.
  - Blue verified badge issued upon automated facial match against profile pictures.
- [ ] **Gemini AI Conversation Coach & Icebreakers**
  - Contextual opener generation powered by the Google Gemini API using mutual interests and bio prompts.
  - Chat revival suggestions when a conversation goes quiet.
- [ ] **Safety & Privacy Center**
  - **Date Check-In**: Share date details and live location with trusted emergency contacts.
  - **Incognito Mode**: Hide profile from discovery; visible only to profiles you swipe right on.
  - **Block Contacts**: Prevent friends, exes, and coworkers from seeing your profile via hashed contact matching.
- [ ] **Encrypted Audio / Video Dates**
  - Secure 1-on-1 peer-to-peer video calls using WebRTC / Agora SDK without sharing phone numbers or personal handles.

---

## 📊 Feature Priority Matrix

| Priority | Feature | Complexity | Impact | Status |
| :--- | :--- | :--- | :--- | :--- |
| **P0** | Native Sign in with Apple & Google OAuth | Medium | Essential for Launch | ✅ Live on TestFlight |
| **P0** | 9-Step Guided Onboarding & Storage | High | User Acquisition & Quality | ✅ Live on TestFlight |
| **P0** | App Store Compliance (Delete, Block/Report, Legal) | Medium | Mandatory for App Store | ✅ Live on TestFlight |
| **P0** | Discovery Story Photo Taps & Swipe Haptics | Medium | Core App Feel & Delight | 🎨 In Progress |
| **P0** | Chat Icebreaker Chips & Read Receipts | Low | Retention & Conversation Rate | 🎨 In Progress |
| **P1** | Push Notifications (APNs / FCM) | Medium | Daily Active Retention | 📍 Phase 4 |
| **P1** | Live GPS & PostGIS Distance Queries | Medium | Discovery Relevance | 📍 Phase 4 |
| **P1** | RevenueCat Subscriptions (Crush Gold) | High | Direct Monetization | 💎 Phase 5 |
| **P2** | Selfie Liveness Verification Badge | Medium | Trust & Anti-Bot Safety | 🛡️ Phase 6 |
| **P2** | Gemini AI Conversation Starters | Low | Chat Engagement | 🛡️ Phase 6 |
