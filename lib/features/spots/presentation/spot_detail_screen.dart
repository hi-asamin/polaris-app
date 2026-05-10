import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:polaris/features/spots/models/spot.dart';
import 'package:polaris/features/spots/models/spot_category_x.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';
import 'package:polaris/features/visits/presentation/visits_provider.dart';
import 'package:polaris/features/visits/presentation/widgets/visit_tile.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';

class SpotDetailScreen extends ConsumerWidget {
  const SpotDetailScreen({required this.spotId, super.key});
  final String spotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spot = ref.watch(spotByIdProvider(spotId));
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final visits = ref.watch(visitsBySpotProvider(spotId));

    if (spot == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Spot not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: scheme.surface,
            foregroundColor: scheme.onSurface,
            stretch: true,
            actions: [
              IconButton(
                tooltip: l.spotDetailWantToVisit,
                onPressed: () => ref
                    .read(spotsNotifierProvider.notifier)
                    .toggleWantToVisit(spot.id),
                icon: Icon(
                  spot.wantToVisit
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: spot.wantToVisit ? scheme.error : null,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _PhotoCarousel(spot: spot),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: spot.primaryCategory.color.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              spot.primaryCategory.icon,
                              size: 14,
                              color: spot.primaryCategory.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              spot.primaryCategory.label(l),
                              style: TextStyle(
                                color: spot.primaryCategory.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (spot.priceLevel != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '¥' * (spot.priceLevel! + 1),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (visits.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: scheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l.spotDetailVisitCount(visits.length),
                                style: TextStyle(
                                  color: scheme.onPrimaryContainer,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l.spotDetailNotVisited,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    spot.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (spot.rating != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          spot.rating!.toStringAsFixed(1),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (spot.ratingCount != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${NumberFormat.decimalPattern().format(spot.ratingCount)})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (spot.address != null)
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: l.spotDetailAddressLabel,
                      value: spot.address!,
                    ),
                  if (spot.openingHours != null)
                    _InfoRow(
                      icon: Icons.schedule_outlined,
                      label: l.spotDetailHoursLabel,
                      value: spot.openingHours!.entries
                          .map((e) => '${e.key} ${e.value}')
                          .join('\n'),
                    ),
                  if (spot.phoneNumber != null)
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: l.spotDetailPhoneLabel,
                      value: spot.phoneNumber!,
                    ),
                  if (spot.websiteUrl != null)
                    _InfoRow(
                      icon: Icons.public,
                      label: l.spotDetailWebsiteLabel,
                      value: spot.websiteUrl!,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.add_circle_outline),
                          label: Text(l.spotDetailAddVisit),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.map_outlined),
                        label: Text(l.spotDetailOpenInMaps),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.spotDetailMemoLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      spot.userMemo ?? l.spotDetailMemoEmpty,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: spot.userMemo != null
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                        fontStyle: spot.userMemo != null
                            ? null
                            : FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        l.spotDetailVisitsLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${visits.length}',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (visits.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      l.spotDetailVisitsEmpty,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: visits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  return VisitTile(
                    visit: visits[i],
                    showSpotName: false,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoCarousel extends StatelessWidget {
  const _PhotoCarousel({required this.spot});
  final Spot spot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (spot.photoUrls.isEmpty) {
      return Container(
        color: spot.primaryCategory.color.withValues(alpha: 0.2),
        child: Center(
          child: Icon(
            spot.primaryCategory.icon,
            size: 80,
            color: spot.primaryCategory.color,
          ),
        ),
      );
    }
    return PageView.builder(
      itemCount: spot.photoUrls.length,
      itemBuilder: (context, i) {
        return CachedNetworkImage(
          imageUrl: spot.photoUrls[i],
          fit: BoxFit.cover,
          placeholder: (c, _) =>
              Container(color: scheme.surfaceContainerHighest),
          errorWidget: (c, _, __) => Container(
            color: spot.primaryCategory.color.withValues(alpha: 0.2),
            child: Icon(
              spot.primaryCategory.icon,
              size: 80,
              color: spot.primaryCategory.color,
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
