import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:crush/core/constants/app_colors.dart';
import 'package:crush/providers/auth_provider.dart';
import 'package:crush/providers/chat_provider.dart';
import 'package:crush/providers/discovery_provider.dart';
import 'package:crush/ui/widgets/action_button.dart';
import 'package:crush/ui/widgets/swipe_card.dart';
import 'package:crush/ui/screens/discovery/filters_sheet.dart';
import 'package:crush/ui/screens/discovery/match_celebration_dialog.dart';
import 'package:crush/ui/screens/discovery/profile_detail_sheet.dart';

class DiscoveryScreen extends StatefulWidget {
  final VoidCallback onNavigateToChat;

  const DiscoveryScreen({
    super.key,
    required this.onNavigateToChat,
  });

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final CardSwiperController _cardSwiperController = CardSwiperController();

  @override
  void dispose() {
    _cardSwiperController.dispose();
    super.dispose();
  }

  void _showFilters(BuildContext context, DiscoveryProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FiltersSheet(
        currentMaxDistance: provider.maxDistanceKm,
        currentAgeRange: provider.ageRange,
        currentGender: provider.genderPreference,
        onApply: (distance, ageRange, gender) {
          provider.updateFilters(
            maxDistance: distance,
            ageRange: ageRange,
            genderPreference: gender,
          );
        },
      ),
    );
  }

  void _showMatchDialog(BuildContext context, DiscoveryProvider discoveryProvider) {
    final matchedProfile = discoveryProvider.lastMatchedProfile;
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (matchedProfile != null && authProvider.currentProfile != null) {
      chatProvider.addMatchFromSwipe(matchedProfile);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => MatchCelebrationDialog(
          currentUser: authProvider.currentProfile!,
          matchedUser: matchedProfile,
          onSendMessage: () {
            Navigator.pop(ctx);
            discoveryProvider.clearMatchCelebration();
            widget.onNavigateToChat();
          },
          onKeepSwiping: () {
            Navigator.pop(ctx);
            discoveryProvider.clearMatchCelebration();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⚡ PERF: Use read() for auth — we only need currentProfile at swipe time,
    // not on every auth state change.
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // ⚡ PERF: Extracted AppBar title as const-compatible widget to avoid
        // ShaderMask being rebuilt on every provider change.
        title: const _CrushAppBarTitle(),
        actions: [
          // ⚡ PERF: Use Selector to get the provider reference without
          // subscribing to all changes here — the button just needs the provider ref.
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
              onPressed: () => _showFilters(ctx, context.read<DiscoveryProvider>()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ⚡ PERF: Selector only rebuilds the card area when isLoading or
            // profiles.length changes — not on every match/rewind notify.
            Expanded(
              child: Selector<DiscoveryProvider, _CardDeckData>(
                selector: (_, p) => _CardDeckData(
                  isLoading: p.isLoading,
                  profileCount: p.profiles.length,
                ),
                builder: (ctx, data, _) {
                  final discoveryProvider = ctx.read<DiscoveryProvider>();

                  if (data.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (data.profileCount == 0) {
                    return _buildEmptyState(discoveryProvider);
                  }

                  final profiles = discoveryProvider.profiles;
                  final displayCount = profiles.length > 2
                      ? 3
                      : profiles.length;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    // ⚡ PERF: RepaintBoundary isolates card repaints from the
                    // rest of the screen (action buttons, AppBar, etc.)
                    child: RepaintBoundary(
                      child: CardSwiper(
                        controller: _cardSwiperController,
                        cardsCount: profiles.length,
                        numberOfCardsDisplayed: displayCount,
                        backCardOffset: const Offset(0, 36),
                        padding: EdgeInsets.zero,
                        cardBuilder: (context, index, percentX, percentY) {
                          if (index < 0 || index >= profiles.length) {
                            return const SizedBox.shrink();
                          }
                          final profile = profiles[index];
                          return SwipeCard(
                            key: ValueKey(profile.id),
                            profile: profile,
                            onInfoTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => FractionallySizedBox(
                                  heightFactor: 0.9,
                                  child: ProfileDetailSheet(profile: profile),
                                ),
                              );
                            },
                          );
                        },
                        onSwipe: (prevIndex, currentIndex, direction) async {
                          final currentUserId =
                              authProvider.currentProfile?.id ?? 'guest';

                          if (direction == CardSwiperDirection.right) {
                            final isMatch = await discoveryProvider.swipeRight(
                              currentUserId: currentUserId,
                            );
                            if (!mounted) return true;
                            if (isMatch) {
                              _showMatchDialog(this.context, discoveryProvider);
                            }
                          } else if (direction == CardSwiperDirection.left) {
                            await discoveryProvider.swipeLeft(
                              currentUserId: currentUserId,
                            );
                          } else if (direction == CardSwiperDirection.top) {
                            final isMatch = await discoveryProvider.swipeUp(
                              currentUserId: currentUserId,
                            );
                            if (!mounted) return true;
                            if (isMatch) {
                              _showMatchDialog(this.context, discoveryProvider);
                            }
                          }
                          return true;
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Action Bar
            // ⚡ PERF: Selector watches only canRewind so only the rewind
            // button rebuilds when swipe history changes, not the whole bar.
            Selector<DiscoveryProvider, bool>(
              selector: (_, p) => p.canRewind,
              builder: (ctx, canRewind, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Rewind
                      ActionButton(
                        icon: Icons.replay_rounded,
                        color: AppColors.rewind,
                        isSecondary: true,
                        onTap: canRewind
                            ? () {
                                _cardSwiperController.undo();
                                ctx.read<DiscoveryProvider>().rewind();
                              }
                            : null,
                      ),

                      // Dislike / Pass
                      ActionButton(
                        icon: Icons.close_rounded,
                        color: AppColors.nope,
                        size: 64,
                        iconSize: 32,
                        onTap: () {
                          _cardSwiperController.swipe(CardSwiperDirection.left);
                        },
                      ),

                      // Super Crush
                      ActionButton(
                        icon: Icons.star_rounded,
                        color: AppColors.superLike,
                        isSecondary: true,
                        onTap: () {
                          _cardSwiperController.swipe(CardSwiperDirection.top);
                        },
                      ),

                      // Like
                      ActionButton(
                        icon: Icons.favorite_rounded,
                        color: AppColors.like,
                        size: 64,
                        iconSize: 32,
                        onTap: () {
                          _cardSwiperController.swipe(CardSwiperDirection.right);
                        },
                      ),

                      // Boost
                      ActionButton(
                        icon: Icons.bolt_rounded,
                        color: AppColors.boost,
                        isSecondary: true,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚡ Crush Boost Activated! Your profile is prioritized.'),
                              backgroundColor: AppColors.surface,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(DiscoveryProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.cardBorder, width: 2),
              ),
              child: const Icon(
                Icons.radar_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No new profiles nearby',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try expanding your distance or age filters to discover more people around you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.loadDiscoveryProfiles(),
              child: const Text('Refresh Feed'),
            ),
          ],
        ),
      ),
    );
  }
}

// ⚡ PERF: Immutable data class for Selector — avoids rebuild unless both
// isLoading AND profileCount are identical to previous values.
class _CardDeckData {
  final bool isLoading;
  final int profileCount;
  const _CardDeckData({required this.isLoading, required this.profileCount});

  @override
  bool operator ==(Object other) =>
      other is _CardDeckData &&
      other.isLoading == isLoading &&
      other.profileCount == profileCount;

  @override
  int get hashCode => Object.hash(isLoading, profileCount);
}

// ⚡ PERF: Extracted as a StatelessWidget so ShaderMask is only built once
// and not re-evaluated on every provider rebuild.
class _CrushAppBarTitle extends StatelessWidget {
  const _CrushAppBarTitle();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: const Text(
              'crush',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
