import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/features/folders/models/folder.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final folders = ref.watch(foldersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.foldersTitle),
        actions: [
          IconButton(
            tooltip: l.foldersNew,
            onPressed: () {},
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
        ],
      ),
      body: folders.isEmpty
          ? _Empty(l: l)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: folders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final f = folders[i];
                return _FolderCard(
                  folder: f,
                  onTap: () => context.push('/folders/${f.id}'),
                );
              },
            ),
    );
  }
}

class _FolderCard extends ConsumerWidget {
  const _FolderCard({required this.folder, required this.onTap});
  final Folder folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final lists = ref.watch(listsByFolderProvider(folder.id));
    final spotCount = ref.watch(spotsCountByFolderProvider(folder.id));
    final l = AppLocalizations.of(context);
    final color = folder.colorValue != null
        ? Color(folder.colorValue!)
        : scheme.primary;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 120,
              child: Stack(
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
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 12,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${l.folderListsCount(lists.length)}・${l.folderSpotsCount(spotCount)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _iconFor(folder.iconName),
                        size: 18,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (lists.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final list in lists.take(4))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _iconFor(list.iconName),
                              size: 14,
                              color: list.colorValue != null
                                  ? Color(list.colorValue!)
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(list.name, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    if (lists.length > 4)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${lists.length - 4}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
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
      return Icons.folder_rounded;
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l});
  final AppLocalizations l;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 56, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(l.folderEmpty, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l.folderEmptyHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
