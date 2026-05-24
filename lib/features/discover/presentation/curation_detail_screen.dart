import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/features/discover/data/curation_mock.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';
import 'package:polaris/features/spots/presentation/widgets/save_to_list_sheet.dart';

class CurationDetailScreen extends ConsumerWidget {
  const CurationDetailScreen({required this.curationId, super.key});
  final String curationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = CurationMock.sectionById(curationId);
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (section == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Curation not found')),
      );
    }

    final heroHeight = MediaQuery.sizeOf(context).height * 0.42;
    final heroImage = section.previewImages.isNotEmpty
        ? section.previewImages.first
        : 'https://picsum.photos/seed/${section.id}/1200/1200';
    final glassStyle = IconButton.styleFrom(
      backgroundColor: Colors.black.withValues(alpha: 0.32),
      foregroundColor: Colors.white,
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: heroHeight,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                style: glassStyle,
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: heroImage,
                    fit: BoxFit.cover,
                    placeholder: (c, _) =>
                        Container(color: scheme.surfaceContainerHigh),
                    errorWidget: (c, _, _) =>
                        Container(color: scheme.surfaceContainerHigh),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xCC000000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          section.subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          section.title,
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.1,
                            shadows: [
                              Shadow(
                                blurRadius: 12,
                                color: Color(0x66000000),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.editorial,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: scheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 2,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${section.spots.length} SPOTS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverList.separated(
              itemCount: section.spots.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                return _CurationSpotCard(
                  spot: section.spots[i],
                  rank: i + 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CurationSpotCard extends ConsumerStatefulWidget {
  const _CurationSpotCard({required this.spot, required this.rank});
  final CurationSpot spot;
  final int rank;

  @override
  ConsumerState<_CurationSpotCard> createState() => _CurationSpotCardState();
}

class _CurationSpotCardState extends ConsumerState<_CurationSpotCard> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final spotId = await ref
          .read(spotsNotifierProvider.notifier)
          .saveFromCurationSpot(widget.spot);
      if (!mounted) return;
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => SaveToListSheet(spotId: spotId),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('スポットを保存しました')),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final firstPhoto = widget.spot.photoUrls.isNotEmpty
        ? widget.spot.photoUrls.first
        : null;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: firstPhoto != null
                        ? CachedNetworkImage(
                            imageUrl: firstPhoto,
                            fit: BoxFit.cover,
                            placeholder: (c, _) => Container(
                              color: scheme.surfaceContainerHighest,
                            ),
                            errorWidget: (c, _, _) => Container(
                              color: scheme.surfaceContainerHighest,
                            ),
                          )
                        : Container(color: scheme.surfaceContainerHighest),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${widget.rank}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.spot.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _SaveButton(saving: _saving, onTap: _save),
                    ],
                  ),
                  if (widget.spot.address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.spot.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (widget.spot.rating != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.spot.rating!.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    widget.spot.editorialNote,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.78),
                      height: 1.5,
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

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saving, required this.onTap});
  final bool saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: saving ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (saving)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimaryContainer,
                  ),
                )
              else
                Icon(
                  Icons.bookmark_add_outlined,
                  size: 16,
                  color: scheme.onPrimaryContainer,
                ),
              const SizedBox(width: 4),
              Text(
                '保存',
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
