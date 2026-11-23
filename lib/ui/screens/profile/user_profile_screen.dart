import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crush/core/constants/app_colors.dart';
import 'package:crush/core/constants/profile_options.dart';
import 'package:crush/models/profile_model.dart';
import 'package:crush/providers/auth_provider.dart';
import 'package:crush/ui/screens/profile/edit_profile_screen.dart';
import 'package:crush/ui/screens/settings/settings_screen.dart';
import 'package:crush/ui/widgets/crush_image.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  void _edit(BuildContext context, [ProfileSection? section]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(initialSection: section),
      ),
    );
  }

  void _openPreview(BuildContext context) {
    // TODO: open ProfileDetailSheet with the user's own profile once that
    // file is updated to accept a preview flag.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preview is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.currentProfile;

    if (profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, profile),
            if (profile.completeness < 1) ...[
              const SizedBox(height: 20),
              _CompletionBanner(
                percent: (profile.completeness * 100).round(),
                onTap: () => _edit(context, profile.nextIncomplete),
              ),
            ],
            const SizedBox(height: 16),
            _buildChips(context, profile),
            const SizedBox(height: 28),
            const _SectionTitle('My Photos'),
            const SizedBox(height: 12),
            _PhotoStrip(
              photos: profile.photos,
              onTap: () => _edit(context, ProfileSection.photos),
            ),
            const SizedBox(height: 28),
            const _SectionTitle('Prompts'),
            const SizedBox(height: 12),
            _buildPrompts(context, profile),
            const SizedBox(height: 28),
            const _GoldBanner(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProfileModel profile) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _edit(context, ProfileSection.photos),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.surfaceLight,
                  backgroundImage: crushImageProvider(profile.primaryPhoto),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      profile.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${profile.age}',
                    style: const TextStyle(
                      fontSize: 22,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (profile.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified,
                        color: Color(0xFF1DA1F2), size: 22),
                  ],
                ],
              ),
              InkWell(
                onTap: () => _openPreview(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChips(BuildContext context, ProfileModel p) {
    Widget chip(
      IconData icon,
      String filledLabel,
      String emptyLabel,
      bool filled,
      ProfileSection section,
    ) {
      return _InfoChip(
        icon: icon,
        label: filled ? filledLabel : emptyLabel,
        filled: filled,
        onTap: () => _edit(context, section),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(Icons.home_outlined, p.city, 'Living in',
            p.city.trim().isNotEmpty, ProfileSection.livingIn),
        chip(Icons.straighten_rounded, '${p.heightCm} cm', 'Height',
            p.heightCm != null, ProfileSection.height),
        chip(Icons.work_outline, p.occupation, 'Job',
            p.occupation.trim().isNotEmpty, ProfileSection.career),
        chip(Icons.school_outlined, p.school, 'Education',
            p.school.trim().isNotEmpty, ProfileSection.education),
        chip(Icons.favorite_border_rounded, p.relationshipGoal ?? '',
            'Looking for', p.relationshipGoal != null, ProfileSection.goal),
        chip(
          Icons.extension_outlined,
          'Basics (${p.basicsFilled}/${ProfileOptions.basics.length})',
          'Basics',
          p.basicsFilled > 0,
          ProfileSection.basics,
        ),
        chip(
          Icons.local_bar_outlined,
          'Lifestyle (${p.lifestyleFilled}/${ProfileOptions.lifestyle.length})',
          'Lifestyle',
          p.lifestyleFilled > 0,
          ProfileSection.lifestyle,
        ),
        chip(
          Icons.interests_outlined,
          'Interests (${p.interests.length}/${ProfileOptions.maxInterests})',
          'Interests',
          p.interests.isNotEmpty,
          ProfileSection.interests,
        ),
      ],
    );
  }

  Widget _buildPrompts(BuildContext context, ProfileModel profile) {
    if (profile.prompts.isEmpty) {
      return _AddCard(
        label: 'Add a prompt',
        onTap: () => _edit(context, ProfileSection.prompts),
      );
    }
    return Column(
      children: [
        for (final p in profile.prompts)
          GestureDetector(
            onTap: () => _edit(context, ProfileSection.prompts),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.prompt,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.answer,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// Pill that deep-links into one profile section. Empty fields show a "+".
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.surface : AppColors.surfaceLight,
      shape: const StadiumBorder(
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: filled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (!filled) ...[
                const SizedBox(width: 6),
                const Icon(Icons.add, size: 16, color: AppColors.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner({required this.percent, required this.onTap});

  final int percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        customBorder:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete your profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percent% done',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        minHeight: 4,
                        backgroundColor: AppColors.surfaceLight,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// All six photo slots in one row. The first empty slot gets a "+".
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos, required this.onTap});

  final List<String> photos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < 6; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AspectRatio(
                        aspectRatio: 0.75,
                        child: i < photos.length
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CrushImage(
                                  imageUrl: photos[i],
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: AppColors.cardBorder),
                                ),
                                child: i == photos.length
                                    ? const Icon(Icons.add,
                                        size: 18, color: AppColors.primary)
                                    : null,
                              ),
                      ),
                    ),
                  ),
              ],
            ),
            if (photos.length < 6) ...[
              const SizedBox(height: 12),
              const Text(
                'Add more photos so people get a better feel for you.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        customBorder:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carried over unchanged from the previous profile screen.
class _GoldBanner extends StatelessWidget {
  const _GoldBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8854D0), Color(0xFFFD297B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crush Gold',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'See who liked you & unlimited rewinds',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Crush Gold activated!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}
