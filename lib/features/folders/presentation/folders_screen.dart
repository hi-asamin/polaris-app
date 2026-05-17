import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/features/folders/models/folder.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';
import 'package:polaris/shared/widgets/photo_collage.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final folders = ref.watch(foldersProvider);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: Text(l.foldersTitle),
            pinned: true,
            actions: [
              IconButton(
                tooltip: l.searchTitle,
                onPressed: () => context.push('/search'),
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                tooltip: l.foldersNew,
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          if (folders.isEmpty)
            SliverFillRemaining(child: _Empty(l: l))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 18,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _PinterestFolderCard(folder: folders[i]),
                  childCount: folders.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PinterestFolderCard extends ConsumerWidget {
  const _PinterestFolderCard({required this.folder});
  final Folder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final photos = ref.watch(folderCoverPhotosProvider(folder.id));
    final spotCount = ref.watch(spotsCountByFolderProvider(folder.id));
    final lists = ref.watch(listsByFolderProvider(folder.id));
    final accent = folder.colorValue != null
        ? Color(folder.colorValue!)
        : scheme.primary;

    return GestureDetector(
      onTap: () => context.push('/folders/${folder.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PhotoCollage(
              photos: photos,
              fallbackColor: accent.withValues(alpha: 0.18),
              fallbackIcon: _iconFor(folder.iconName),
            ),
            // 上から下への暗いグラデーション (テキストの可読性確保)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.55, 1],
                  colors: [
                    Color(0x00000000),
                    Color(0x33000000),
                    Color(0xCC000000),
                  ],
                ),
              ),
            ),
            // メタ情報のチップ (右上)
            Positioned(
              top: 10,
              left: 10,
              child: _FolderBadge(
                icon: _iconFor(folder.iconName),
                color: accent,
              ),
            ),
            // タイトル + サブテキスト
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: _FolderCaption(
                name: folder.name,
                lists: lists.length,
                spots: spotCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderBadge extends StatelessWidget {
  const _FolderBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _FolderCaption extends StatelessWidget {
  const _FolderCaption({
    required this.name,
    required this.lists,
    required this.spots,
  });
  final String name;
  final int lists;
  final int spots;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.2,
            shadows: [
              Shadow(blurRadius: 8, color: Color(0x66000000)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$spots件 ・ $listsリスト',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ],
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 40,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.folderEmpty,
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
