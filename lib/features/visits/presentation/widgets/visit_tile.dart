import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:polaris/features/spots/models/spot.dart';
import 'package:polaris/features/visits/models/visit.dart';

class VisitTile extends StatelessWidget {
  const VisitTile({
    required this.visit,
    this.spot,
    this.onTap,
    this.showSpotName = true,
    super.key,
  });

  final Visit visit;
  final Spot? spot;
  final VoidCallback? onTap;
  final bool showSpotName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final dateFmt = DateFormat('y年M月d日 (E) HH:mm', 'ja');
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showSpotName && spot != null)
                          Text(
                            spot!.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          dateFmt.format(visit.visitedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (visit.rating != null)
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < visit.rating!
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 16,
                          color: const Color(0xFFFFC107),
                        );
                      }),
                    ),
                ],
              ),
              if (visit.memo != null && visit.memo!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  visit.memo!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (visit.companions != null || visit.costJpy != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (visit.companions != null)
                      _Chip(
                        icon: Icons.people_outline,
                        label: visit.companions!,
                      ),
                    if (visit.costJpy != null)
                      _Chip(
                        icon: Icons.payments_outlined,
                        label: '¥${visit.costJpy}',
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
