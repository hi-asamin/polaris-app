import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/lists/models/spot_list.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/features/spots/models/spot.dart';
import 'package:polaris/features/spots/models/spot_category_x.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';
import 'package:polaris/features/visits/presentation/visits_provider.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';

class ListDetailScreen extends ConsumerStatefulWidget {
  const ListDetailScreen({required this.listId, super.key});
  final String listId;

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  SortMode _sort = SortMode.manual;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = ref.watch(listByIdProvider(widget.listId));
    final spots = ref.watch(spotsByListProvider(widget.listId));
    final folder = list != null
        ? ref.watch(folderByIdProvider(list.folderId))
        : null;
    final scheme = Theme.of(context).colorScheme;

    if (list == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('List not found')),
      );
    }

    final accent = list.colorValue != null
        ? Color(list.colorValue!)
        : scheme.primary;
    final sorted = [...spots];
    switch (_sort) {
      case SortMode.name:
        sorted.sort((a, b) => a.name.compareTo(b.name));
      case SortMode.addedAt:
      case SortMode.distance:
      case SortMode.manual:
        break;
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: scheme.surface,
            foregroundColor: scheme.onSurface,
            title: Text(list.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.ios_share_rounded),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (folder != null)
                    Row(
                      children: [
                        Icon(
                          Icons.folder_rounded,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          folder.name,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Text(
                    list.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l.listSpotsCount(spots.length),
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _SortButton(
                        current: _sort,
                        onSelect: (m) => setState(() => _sort = m),
                        l: l,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (sorted.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  l.listEmpty,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final spot = sorted[i];
                    final visitCount = ref.watch(
                      visitCountBySpotProvider(spot.id),
                    );
                    return _PinSpotCard(
                      spot: spot,
                      visitCount: visitCount,
                      onTap: () => context.push('/spots/${spot.id}'),
                    );
                  },
                  childCount: sorted.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PinSpotCard extends StatelessWidget {
  const _PinSpotCard({
    required this.spot,
    required this.visitCount,
    required this.onTap,
  });

  final Spot spot;
  final int visitCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final firstPhoto = spot.photoUrls.isNotEmpty ? spot.photoUrls.first : null;
    final cat = spot.primaryCategory;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (firstPhoto != null)
                    CachedNetworkImage(
                      imageUrl: firstPhoto,
                      fit: BoxFit.cover,
                      placeholder: (c, _) =>
                          Container(color: scheme.surfaceContainerHighest),
                      errorWidget: (c, _, _) => Container(
                        color: cat.color.withValues(alpha: 0.18),
                        child: Icon(cat.icon, color: cat.color, size: 32),
                      ),
                    )
                  else
                    Container(
                      color: cat.color.withValues(alpha: 0.18),
                      child: Icon(cat.icon, color: cat.color, size: 32),
                    ),
                  if (spot.wantToVisit)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: scheme.error,
                        ),
                      ),
                    ),
                  if (visitCount > 0)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$visitCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(cat.icon, size: 12, color: cat.color),
                    const SizedBox(width: 4),
                    if (spot.rating != null) ...[
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 1),
                      Text(
                        spot.rating!.toStringAsFixed(1),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (spot.city != null)
                      Expanded(
                        child: Text(
                          spot.city!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.current,
    required this.onSelect,
    required this.l,
  });
  final SortMode current;
  final ValueChanged<SortMode> onSelect;
  final AppLocalizations l;

  String _label(SortMode m) {
    switch (m) {
      case SortMode.manual:
        return l.listSortManual;
      case SortMode.addedAt:
        return l.listSortAddedAt;
      case SortMode.distance:
        return l.listSortDistance;
      case SortMode.name:
        return l.listSortName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<SortMode>(
      tooltip: l.listSortLabel,
      onSelected: onSelect,
      itemBuilder: (context) => [
        for (final m in SortMode.values)
          PopupMenuItem(value: m, child: Text(_label(m))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              _label(current),
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
