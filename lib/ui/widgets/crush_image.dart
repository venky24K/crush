import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:crush/core/constants/app_colors.dart';

/// Universal image display widget that gracefully handles:
/// 1. Remote HTTP/HTTPS URLs (via CachedNetworkImage with caching & shimmer)
/// 2. Local device file paths (/var/mobile/..., /Users/..., file://...)
/// 3. Missing/broken files (with a clean branded fallback rather than red 'X' errors)
class CrushImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const CrushImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth = 1080,
    this.memCacheHeight,
  });

  bool get _isNetwork {
    if (imageUrl == null) return false;
    final url = imageUrl!.trim();
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) return placeholder!;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2ED),
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFAF5F0),
            Color(0xFFEFE8E1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.favorite_rounded,
          color: AppColors.primary.withValues(alpha: 0.18),
          size: 44,
        ),
      ),
    );
  }

  Widget _buildFallback() {
    if (errorWidget != null) return errorWidget!;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: AppColors.textMuted,
          size: 36,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    final url = imageUrl?.trim() ?? '';

    if (url.isEmpty) {
      imageWidget = _buildFallback();
    } else if (_isNetwork) {
      imageWidget = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        maxWidthDiskCache: 1440,
        maxHeightDiskCache: 1920,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 150),
        placeholder: (context, _) => _buildPlaceholder(),
        errorWidget: (context, _, error) => _buildFallback(),
      );
    } else {
      // Local device file path
      final cleanPath = url.replaceFirst('file://', '');
      final file = File(cleanPath);

      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, _, error) => _buildFallback(),
        );
      } else {
        imageWidget = _buildFallback();
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Helper function to create an ImageProvider for CircleAvatar / BoxDecoration
ImageProvider? crushImageProvider(String? photoUri, {int? maxWidth}) {
  if (photoUri == null || photoUri.trim().isEmpty) {
    return null;
  }

  final uri = photoUri.trim();
  if (uri.startsWith('http://') || uri.startsWith('https://')) {
    return CachedNetworkImageProvider(
      uri,
      maxWidth: maxWidth ?? 1080,
    );
  }

  final cleanPath = uri.replaceFirst('file://', '');
  final file = File(cleanPath);
  if (file.existsSync()) {
    return FileImage(file);
  }

  return null;
}
