import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/lists/models/spot_list.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';

class FolderDetailScreen extends ConsumerWidget {
  const FolderDetailScreen({required this.folderId, super.key});
  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final folder = ref.watch(folderByIdProvider(folderId));
    final lists = ref.watch(listsByFolderProvider(folderId));
    final scheme = Theme.of(context).colorScheme;

    if (folder == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Folder not found')),
      );
    }
    final color = folder.colorValue != null
        ? Color(folder.colorValue!)
        : scheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: scheme.surface,
            foregroundColor: scheme.onSurface,
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(folder.name),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (folder.coverPhotoUrl != null)
                    CachedNetworkImage(
                      imageUrl: folder.coverPhotoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (c, _) =>
                          Container(color: color.withValues(alpha: 0.2)),
                      errorWidget: (c, _, __) =>
                          Container(color: color.withValues(alpha: 0.2)),
                    )
                  else
                    Container(color: color.withValues(alpha: 0.2)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (lists.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('リストがありません')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList.separated(
                itemCount: lists.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final list = lists[i];
                  return _ListTile(
                    list: list,
                    onTap: () => context.push('/lists/${list.id}'),
                    l: l,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ListTile extends ConsumerWidget {
  const _ListTile({
    required this.list,
    required this.onTap,
    required this.l,
  });
  final SpotList list;
  final VoidCallback onTap;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final spotCount = ref.watch(spotsCountByListProvider(list.id));
    final color = list.colorValue != null
        ? Color(list.colorValue!)
        : scheme.primary;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconFor(list.iconName), color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.folderSpotsCount(spotCount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(String? name) {
  switch (name) {
    case 'location_city':
      return Icons.location_city;
    case 'temple_buddhist':
      return Icons.temple_buddhist;
    case 'temple_hindu':
      return Icons.temple_hindu;
    case 'favorite':
      return Icons.favorite;
    case 'local_cafe':
      return Icons.local_cafe;
    case 'ramen_dining':
      return Icons.ramen_dining;
    case 'photo_camera':
      return Icons.photo_camera;
    case 'restaurant':
      return Icons.restaurant;
    case 'hotel':
      return Icons.hotel;
    case 'nightlight_round':
      return Icons.nightlight_round;
    case 'coffee':
      return Icons.coffee;
    default:
      return Icons.list;
  }
}
