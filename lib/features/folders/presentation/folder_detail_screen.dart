import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/lists/models/spot_list.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';
import 'package:polaris/shared/widgets/photo_collage.dart';

class FolderDetailScreen extends ConsumerWidget {
  const FolderDetailScreen({required this.folderId, super.key});
  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
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
                l: l,
              ),
            ),
          ),
          if (lists.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('リストがありません')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 18,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _PinterestListCard(list: lists[i]),
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
    required this.l,
  });
  final String folderName;
  final String? coverPhotoUrl;
  final Color accent;
  final int listsCount;
  final int spotsCount;
  final AppLocalizations l;

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
                '$spotsCount件のスポット ・ $listsCountリスト',
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

class _PinterestListCard extends ConsumerWidget {
  const _PinterestListCard({required this.list});
  final SpotList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final photos = ref.watch(listCoverPhotosProvider(list.id));
    final spotCount = ref.watch(spotsCountByListProvider(list.id));
    final accent = list.colorValue != null
        ? Color(list.colorValue!)
        : scheme.primary;

    return GestureDetector(
      onTap: () => context.push('/lists/${list.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PhotoCollage(
              photos: photos,
              fallbackColor: accent.withValues(alpha: 0.18),
              fallbackIcon: _iconFor(list.iconName),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.55, 1],
                  colors: [Color(0x00000000), Color(0xCC000000)],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: _ListBadge(icon: _iconFor(list.iconName), color: accent),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(blurRadius: 6, color: Color(0x66000000)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$spotCount件',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

class _ListBadge extends StatelessWidget {
  const _ListBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 15, color: color),
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
      return Icons.list_alt_rounded;
  }
}
