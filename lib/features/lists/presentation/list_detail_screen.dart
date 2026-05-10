import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/lists/models/spot_list.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';
import 'package:polaris/features/spots/presentation/widgets/spot_card.dart';
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

    final color = list.colorValue != null
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
      appBar: AppBar(
        title: Text(list.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  if (folder != null) ...[
                    Icon(
                      Icons.folder_rounded,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      folder.name,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    Text('・', style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l.listSpotsCount(spots.length),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final spot = sorted[i];
                  final visitCount = ref.watch(
                    visitCountBySpotProvider(spot.id),
                  );
                  return SpotCard(
                    spot: spot,
                    visitCount: visitCount,
                    onTap: () => context.push('/spots/${spot.id}'),
                  );
                },
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              _label(current),
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
