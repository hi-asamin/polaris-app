import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:polaris/features/spots/models/spot.dart';
import 'package:polaris/features/spots/models/spot_category_x.dart';

class SpotCard extends StatelessWidget {
  const SpotCard({
    required this.spot,
    required this.visitCount,
    this.onTap,
    super.key,
  });

  final Spot spot;
  final int visitCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final firstPhoto = spot.photoUrls.isNotEmpty ? spot.photoUrls.first : null;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: firstPhoto != null
                      ? CachedNetworkImage(
                          imageUrl: firstPhoto,
                          fit: BoxFit.cover,
                          placeholder: (c, _) => Container(
                            color: scheme.surfaceContainerHighest,
                          ),
                          errorWidget: (c, _, __) => Container(
                            color: scheme.surfaceContainerHighest,
                            child: Icon(
                              spot.primaryCategory.icon,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : Container(
                          color: scheme.surfaceContainerHighest,
                          child: Icon(
                            spot.primaryCategory.icon,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (spot.address != null)
                      Text(
                        spot.address!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          spot.primaryCategory.icon,
                          size: 14,
                          color: spot.primaryCategory.color,
                        ),
                        const SizedBox(width: 6),
                        if (spot.rating != null) ...[
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFFFC107),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            spot.rating!.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (visitCount > 0) ...[
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$visitCount',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (spot.wantToVisit)
                          Icon(
                            Icons.favorite_rounded,
                            size: 16,
                            color: scheme.error,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
