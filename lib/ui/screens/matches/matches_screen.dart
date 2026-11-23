import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:crush/core/constants/app_colors.dart';
import 'package:crush/models/match_model.dart';
import 'package:crush/models/profile_model.dart';
import 'package:crush/providers/auth_provider.dart';
import 'package:crush/providers/chat_provider.dart';
import 'package:crush/ui/screens/discovery/match_celebration_dialog.dart';
import 'package:crush/ui/screens/discovery/profile_detail_sheet.dart';
import 'package:crush/ui/screens/matches/chat_screen.dart';
import 'package:crush/ui/widgets/crush_image.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0; // 0 = Messages, 1 = Likes You

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    if (auth.currentProfile != null) {
      final userId = auth.currentProfile!.id;
      final chatProvider = context.read<ChatProvider>();
      chatProvider.loadMatches(userId);
      chatProvider.loadIncomingLikes(userId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleAcceptLike(ProfileModel likedProfile) async {
    final auth = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final myProfile = auth.currentProfile;
    if (myProfile == null) return;

    final createdMatch = await chatProvider.acceptLike(
      currentUserId: myProfile.id,
      targetProfile: likedProfile,
    );

    if (!mounted) return;

    // Show Match Celebration Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => MatchCelebrationDialog(
        currentUser: myProfile,
        matchedUser: likedProfile,
        onSendMessage: () {
          Navigator.pop(dialogCtx);
          if (createdMatch != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(match: createdMatch)),
            );
          }
        },
        onKeepSwiping: () {
          Navigator.pop(dialogCtx);
        },
      ),
    );
  }

  Future<void> _handleRejectLike(ProfileModel likedProfile) async {
    final auth = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final myProfile = auth.currentProfile;
    if (myProfile == null) return;

    await chatProvider.rejectLike(
      currentUserId: myProfile.id,
      targetUserId: likedProfile.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passed on ${likedProfile.fullName}'),
          backgroundColor: AppColors.surface,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _openProfileDetail(ProfileModel profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ProfileDetailSheet(
          profile: profile,
          onLike: () {
            Navigator.pop(context);
            _handleAcceptLike(profile);
          },
          onPass: () {
            Navigator.pop(context);
            _handleRejectLike(profile);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final matches = chatProvider.matches;
    final incomingLikes = chatProvider.incomingLikes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Matches & Messages'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildSegmentTab(
                  title: 'Messages',
                  count: matches.length,
                  isSelected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                const SizedBox(width: 8),
                _buildSegmentTab(
                  title: 'Likes You',
                  count: incomingLikes.length,
                  badgeColor: AppColors.primary,
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => _loadData(),
          child: _selectedTab == 0
              ? _buildMessagesTab(matches, incomingLikes)
              : _buildLikesYouTab(incomingLikes),
        ),
      ),
    );
  }

  Widget _buildSegmentTab({
    required String title,
    required int count,
    required bool isSelected,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (badgeColor ?? AppColors.textMuted).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : (badgeColor ?? AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── TAB 0: Messages & New Matches ──────────────────────────────────────────

  Widget _buildMessagesTab(List<MatchModel> matches, List<ProfileModel> incomingLikes) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search matches...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),

        // Inbound Likes Strip (if any pending)
        if (incomingLikes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Likes You (${incomingLikes.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedTab = 1),
                  child: const Text('See All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      )),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: incomingLikes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final likedProfile = incomingLikes[index];
                return _buildIncomingLikeCard(likedProfile, width: 130);
              },
            ),
          ),
          const Divider(color: AppColors.cardBorder, height: 24),
        ],

        // New Matches Avatars
        if (matches.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'New Matches',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: matches.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final match = matches[index];
                return _buildMatchAvatarItem(context, match);
              },
            ),
          ),
          const Divider(color: AppColors.cardBorder, height: 24),
        ],

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            'Messages',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        // Conversations List
        if (matches.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: matches.length,
            separatorBuilder: (context, index) =>
                const Divider(color: AppColors.cardBorder, height: 16),
            itemBuilder: (context, index) {
              final match = matches[index];
              return _buildConversationTile(context, match);
            },
          ),
      ],
    );
  }

  // ─── TAB 1: Likes You (Accept / Reject) ─────────────────────────────────────

  Widget _buildLikesYouTab(List<ProfileModel> incomingLikes) {
    if (incomingLikes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No new likes yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'When someone swipes right on your profile, they will appear here so you can accept or pass!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: incomingLikes.length,
      itemBuilder: (context, index) {
        final profile = incomingLikes[index];
        return _buildIncomingLikeCard(profile);
      },
    );
  }

  // ─── Reusable Card for Inbound Likes ────────────────────────────────────────

  Widget _buildIncomingLikeCard(ProfileModel profile, {double? width}) {
    return GestureDetector(
      onTap: () => _openProfileDetail(profile),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Profile Photo
            CrushImage(
              imageUrl: profile.primaryPhoto,
              fit: BoxFit.cover,
            ),

            // Gradient Overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.35, 1.0],
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),

            // Name & Age & Buttons
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${profile.fullName.split(' ').first}, ${profile.age}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (profile.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Color(0xFF1DA1F2), size: 14),
                      ],
                    ],
                  ),
                  if (profile.city.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      profile.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Accept (Heart) and Reject (X) Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reject / Pass button
                      GestureDetector(
                        onTap: () => _handleRejectLike(profile),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.5),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        ),
                      ),

                      // Accept / Like button
                      GestureDetector(
                        onTap: () => _handleAcceptLike(profile),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Existing Avatar & Conversation Tiles ───────────────────────────────────

  Widget _buildMatchAvatarItem(BuildContext context, MatchModel match) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(match: match)),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.surfaceLight,
              backgroundImage: crushImageProvider(match.user.primaryPhoto),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            match.user.fullName.split(' ').first,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, MatchModel match) {
    final timeStr = DateFormat('hh:mm a').format(match.lastMessageAt);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(match: match)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.surfaceLight,
              backgroundImage: crushImageProvider(match.user.primaryPhoto),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        match.user.fullName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: match.hasUnread ? FontWeight.w800 : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: match.hasUnread ? AppColors.primary : AppColors.textMuted,
                          fontWeight: match.hasUnread ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.lastMessage.isNotEmpty
                              ? match.lastMessage
                              : 'Say hello to your new match 👋',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: match.hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: match.hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (match.hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 38,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No matches yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep swiping to discover and match with amazing people!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
