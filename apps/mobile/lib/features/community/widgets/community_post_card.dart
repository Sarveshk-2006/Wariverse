import 'package:flutter/material.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/utils/wari_formatters.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';

class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    this.onUpvote,
  });

  final CommunityPost post;
  final VoidCallback? onUpvote;

  @override
  Widget build(BuildContext context) {
    return WariCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: WariColors.primaryLight,
                child: Text(
                  post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
                  style: WariTypography.titleSmall.copyWith(color: WariColors.primaryDark),
                ),
              ),
              const SizedBox(width: WariSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.authorName,
                            style: WariTypography.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (post.isVerified) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: WariColors.successLight,
                              borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, size: 11, color: WariColors.success),
                                const SizedBox(width: 2),
                                Text(
                                  'VERIFIED',
                                  style: WariTypography.caption.copyWith(
                                    color: WariColors.success,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      WariFormatters.timeAgo(post.createdAt.toIso8601String()),
                      style: WariTypography.caption,
                    ),
                  ],
                ),
              ),
              WariStatusChip(
                label: post.postType.displayName,
                color: _getPostTypeColor(post.postType),
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.sm),

          Text(post.message, style: WariTypography.bodyMedium),
          const SizedBox(height: WariSpacing.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, size: 12, color: WariColors.textMuted),
                  const SizedBox(width: 2),
                  Text('Within ${post.radiusKm.toStringAsFixed(1)} km radius', style: WariTypography.caption),
                ],
              ),
              InkWell(
                onTap: onUpvote,
                borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: WariColors.slate100,
                    borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.thumb_up_alt_outlined, size: 14, color: WariColors.primary),
                      const SizedBox(width: 4),
                      Text('${post.upvotes}', style: WariTypography.labelSmall.copyWith(color: WariColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _getPostTypeColor(PostType type) {
    switch (type) {
      case PostType.FOOD_AVAILABLE: return WariColors.foodColor;
      case PostType.WATER_AVAILABLE: return WariColors.waterColor;
      case PostType.SHELTER_AVAILABLE: return WariColors.shelterColor;
      case PostType.MEDICAL_HELP: return WariColors.danger;
      case PostType.ROUTE_WARNING: return WariColors.warning;
      case PostType.WEATHER_WARNING: return WariColors.warning;
      case PostType.LOST_PERSON: return WariColors.accent;
      case PostType.FOUND_PERSON: return WariColors.success;
      case PostType.HELP_REQUEST: return WariColors.warning;
      case PostType.GENERAL: return WariColors.primary;
    }
  }
}
