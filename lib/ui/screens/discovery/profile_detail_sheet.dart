import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crush/core/constants/app_colors.dart';
import 'package:crush/models/profile_model.dart';
import 'package:crush/ui/widgets/interest_chip.dart';

class ProfileDetailSheet extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback? onLike;
  final VoidCallback? onPass;
  final VoidCallback? onSuperLike;

  const ProfileDetailSheet({
    super.key,
    required this.profile,
    this.onLike,
    this.onPass,
    this.onSuperLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 380,
                    child: Builder(
                      builder: (context) {
                        final photos = profile.photos.isNotEmpty
                            ? profile.photos
                            : [profile.primaryPhoto];
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CachedNetworkImage(
                                imageUrl: photos[index],
                                width: 280,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Text(
                        profile.fullName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${profile.age}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (profile.isVerified) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF1DA1F2),
                          size: 24,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${profile.city.isNotEmpty ? "${profile.city} • " : ""}${profile.distanceKm.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const Divider(color: AppColors.cardBorder, height: 32),

                  if (profile.bio.isNotEmpty) ...[
                    const Text(
                      'About Me',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.bio,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Text(
                    'Essentials',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (profile.occupation.isNotEmpty)
                        _buildInfoPill(Icons.work_outline, profile.occupation),
                      if (profile.school.isNotEmpty)
                        _buildInfoPill(Icons.school_outlined, profile.school),
                      _buildInfoPill(Icons.favorite_border, 'Looking for relationship'),
                      _buildInfoPill(Icons.straighten, '5\'9" (175 cm)'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (profile.interests.isNotEmpty) ...[
                    const Text(
                      'Passions & Interests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interests.map((tag) {
                        return InterestChip(label: tag);
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${profile.fullName} reported and hidden.'),
                            backgroundColor: AppColors.surface,
                          ),
                        );
                      },
                      icon: const Icon(Icons.flag_outlined, color: AppColors.textMuted, size: 18),
                      label: Text(
                        'Report ${profile.fullName}',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
