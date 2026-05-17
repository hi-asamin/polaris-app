import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/core/utils/relative_date.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/lists/models/spot_list.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/shared/widgets/photo_collage.dart';

class FolderDetailScreen extends ConsumerWidget {
  const FolderDetailScreen({required this.folderId, super.key});
  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folder = ref.watch(folderByIdProvider(folderId));
    final lists = ref.watch(listsByFolderProvider(folderId));
    final spotCount = ref.watch(spotsCountByFolderProvider(folderId));
    final scheme = Theme.of(context).colorScheme;

    if (folder == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Folder not found')),
      );
    }
    final accent = folder.colorValue != null
        ? Color(folder.colorValue!)
        : scheme.primary;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            backgroundColor: scheme.surface,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            actionsIconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.ios_share_rounded),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: _FolderHeader(
                folderName: folder.name,
                coverPhotoUrl: folder.coverPhotoUrl,
                accent: accent,
                listsCount: lists.length,
                spotsCount: spotCount,
                updatedAt: folder.updatedAt,
              ),
            ),
          ),
          if (lists.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('リストがありません')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _FavoriteListCard(list: lists[i]),
                  childCount: lists.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FolderHeader extends StatelessWidget {
  const _FolderHeader({
    required this.folderName,
    required this.coverPhotoUrl,
    required this.accent,
    required this.listsCount,
    required this.spotsCount,
    required this.updatedAt,
  });
  final String folderName;
  final String? coverPhotoUrl;
  final Color accent;
  final int listsCount;
  final int spotsCount;
  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (coverPhotoUrl != null)
          CachedNetworkImage(
            imageUrl: coverPhotoUrl!,
            fit: BoxFit.cover,
            placeholder: (c, _) =>
                Container(color: accent.withValues(alpha: 0.2)),
            errorWidget: (c, _, _) =>
                Container(color: accent.withValues(alpha: 0.2)),
          )
        else
          Container(color: accent.withValues(alpha: 0.2)),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.5, 1],
              colors: [
                Color(0x66000000),
                Color(0x33000000),
                Color(0xCC000000),
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                folderName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.1,
                  shadows: [
                    Shadow(blurRadius: 12, color: Color(0x66000000)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$spotsCount件のスポット ・ $listsCountリスト ・ ${relativeDate(updatedAt)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FavoriteListCard extends ConsumerWidget {
  const _FavoriteListCard({required this.list});
  final SpotList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final photos = ref.watch(listCoverPhotosProvider(list.id));
    final spotCount = ref.watch(spotsCountByListProvider(list.id));
    final accent = list.colorValue != null
        ? Color(list.colorValue!)
        : scheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/lists/${list.id}'),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: scheme.surface,
                  child: PhotoCollage(
                    photos: photos,
                    gap: 2,
                    fallbackColor: accent.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InkResponse(
                  onTap: () {},
                  radius: 18,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'スポット：$spotCount 件',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
