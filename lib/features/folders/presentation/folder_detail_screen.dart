import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/core/db/system_entities.dart';
import 'package:polaris/core/utils/relative_date.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/spots/models/spot.dart';
import 'package:polaris/features/spots/models/spot_category_x.dart';
import 'package:polaris/features/visits/presentation/visits_provider.dart';
import 'package:polaris/shared/widgets/photo_collage.dart';

/// フォルダ詳細。1 階層構造に移行後、フォルダ直下にスポットが並ぶ。
/// (旧仕様ではここに「リスト」のカードが並んでいた)
class FolderDetailScreen extends ConsumerWidget {
  const FolderDetailScreen({required this.folderId, super.key});
  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folder = ref.watch(folderByIdProvider(folderId));
    final spots = ref.watch(spotsByFolderProvider(folderId));
    final scheme = Theme.of(context).colorScheme;

    if (folder == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Folder not found')),
      );
    }
    final isSystem = SystemIds.protectedFolderIds.contains(folder.id);
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
              if (!isSystem)
                IconButton(
                  tooltip: 'シェア',
                  onPressed: () => context.push('/share/folder/$folderId'),
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
                spotsCount: spots.length,
                updatedAt: folder.updatedAt,
                isSystem: isSystem,
              ),
            ),
          ),
          if (spots.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    isSystem
                        ? '気になる場所を保存しよう'
                        : 'まだスポットがありません',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final spot = spots[i];
                    final visitCount = ref.watch(
                      visitCountBySpotProvider(spot.id),
                    );
                    return _SpotPinCard(
                      spot: spot,
                      visitCount: visitCount,
                      onTap: () => context.push('/spots/${spot.id}'),
                    );
                  },
                  childCount: spots.length,
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
    required this.spotsCount,
    required this.updatedAt,
    required this.isSystem,
  });
  final String folderName;
  final String? coverPhotoUrl;
  final Color accent;
  final int spotsCount;
  final DateTime updatedAt;
  final bool isSystem;

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
              if (isSystem)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_rounded, size: 12, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        'デフォルト',
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
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
                '$spotsCount件のスポット ・ ${relativeDate(updatedAt)}',
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

class _SpotPinCard extends StatelessWidget {
  const _SpotPinCard({
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
    final cat = spot.primaryCategory;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (spot.photoUrls.isNotEmpty)
                    PhotoCollage(
                      photos: spot.photoUrls.take(1).toList(),
                      gap: 0,
                      fallbackColor: cat.color.withValues(alpha: 0.18),
                    )
                  else
                    Container(
                      color: cat.color.withValues(alpha: 0.18),
                      child: Icon(cat.icon, color: cat.color, size: 32),
                    ),
                  if (spot.isFavorite)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 12,
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
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '訪問 $visitCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            spot.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(cat.icon, size: 12, color: cat.color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  spot.city ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (spot.rating != null) ...[
                const Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: Color(0xFFFFC107),
                ),
                const SizedBox(width: 2),
                Text(
                  spot.rating!.toStringAsFixed(1),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
