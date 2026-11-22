import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:crush/core/constants/app_colors.dart';
import 'package:crush/models/profile_model.dart';
import 'package:crush/ui/widgets/crush_image.dart';

class SwipeCard extends StatefulWidget {
  final ProfileModel profile;
  final VoidCallback? onInfoTap;

  const SwipeCard({
    super.key,
    required this.profile,
    this.onInfoTap,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheRemainingPhotos();
    });
  }

  @override
  void didUpdateWidget(covariant SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id) {
      _currentPhotoIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _precacheRemainingPhotos();
      });
    }
  }

  /// Proactively pre-caches all photos of this profile into memory
  /// so tapping left/right to view other pictures is instant with 0ms lag.
  void _precacheRemainingPhotos() {
    if (!mounted) return;
    for (final photo in widget.profile.photos) {
      if (photo.startsWith('http://') || photo.startsWith('https://')) {
        precacheImage(
          CachedNetworkImageProvider(photo, maxWidth: 1080),
          context,
        ).catchError((_) {});
      }
    }
  }

  void _nextPhoto(int totalPhotos) {
    if (_currentPhotoIndex < totalPhotos - 1) {
      setState(() => _currentPhotoIndex++);
    }
  }

  void _previousPhoto() {
    if (_currentPhotoIndex > 0) {
      setState(() => _currentPhotoIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.profile.photos.isNotEmpty
        ? widget.profile.photos
        : [widget.profile.primaryPhoto];

    final safeIndex = _currentPhotoIndex.clamp(0, photos.length - 1);

    // ⚡ PERF: RepaintBoundary prevents the card from repainting sibling cards
    return RepaintBoundary(
      child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: AppColors.surface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Current Photo (supports network URLs & local file paths seamlessly)
            CrushImage(
              imageUrl: photos[safeIndex],
              fit: BoxFit.cover,
              memCacheWidth: 1080,
              errorWidget: Container(
                color: AppColors.surfaceLight,
                child: const Icon(
                  Icons.person,
                  size: 80,
                  color: AppColors.textMuted,
                ),
              ),
            ),

            // Top story indicator bars
            if (photos.length > 1)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: List.generate(
                    photos.length,
                    (index) => Expanded(
                      child: Container(
                        height: 3.5,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: index == safeIndex
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Tap gestures for photo switching
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _previousPhoto,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _nextPhoto(photos.length),
                    ),
                  ),
                ],
              ),
            ),

            // Gradient Overlay for Profile Info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.cardOverlayGradient,
                ),
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name, Age & Verified
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.profile.fullName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.profile.age}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.profile.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF1DA1F2),
                            size: 22,
                          ),
                        ],
                        const Spacer(),
                        GestureDetector(
                          onTap: widget.onInfoTap,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Occupation
                    if (widget.profile.occupation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.work_outline_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.profile.occupation,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // City & Distance
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.profile.city.isNotEmpty ? "${widget.profile.city} • " : ""}${widget.profile.distanceKm.toStringAsFixed(1)} km away',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    // Interest tags preview
                    if (widget.profile.interests.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.profile.interests.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.cardBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
