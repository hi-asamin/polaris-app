import 'package:flutter/material.dart';
import 'package:polaris/features/folders/models/folder.dart';
import 'package:polaris/shared/widgets/photo_collage.dart';

/// シェア用の 9:16 縦長カード。
/// `RepaintBoundary` でこの widget を画像に焼き付ける想定。
class FolderShareCard extends StatelessWidget {
  const FolderShareCard({
    required this.folder,
    required this.photos,
    required this.spotCount,
    required this.listsCount,
    super.key,
  });

  final Folder folder;
  final List<String> photos;
  final int spotCount;
  final int listsCount;

  @override
  Widget build(BuildContext context) {
    final accent = folder.colorValue != null
        ? Color(folder.colorValue!)
        : const Color(0xFF1B5BD8);
    const bg = Color(0xFFFBFAF7);
    const ink = Color(0xFF111418);

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: bg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 内部の寸法をカード幅基準で決め、画面サイズに依存しないようにする。
            final w = constraints.maxWidth;
            final pad = w * 0.06;
            return Padding(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, pad * 0.8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBrandMark(accent: accent, ink: ink, scale: w),
                  SizedBox(height: w * 0.04),
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(w * 0.04),
                      child: PhotoCollage(
                        photos: photos,
                        fallbackColor: accent.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                  SizedBox(height: w * 0.06),
                  Expanded(
                    flex: 4,
                    child: _CardBody(
                      folderName: folder.name,
                      spotCount: spotCount,
                      listsCount: listsCount,
                      accent: accent,
                      ink: ink,
                      scale: w,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBrandMark extends StatelessWidget {
  const _TopBrandMark({
    required this.accent,
    required this.ink,
    required this.scale,
  });
  final Color accent;
  final Color ink;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: scale * 0.03,
            vertical: scale * 0.012,
          ),
          decoration: BoxDecoration(
            color: ink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(scale * 0.06),
          ),
          child: Text(
            'Curated on polaris',
            style: TextStyle(
              fontSize: scale * 0.032,
              fontWeight: FontWeight.w600,
              color: ink.withValues(alpha: 0.6),
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          width: scale * 0.075,
          height: scale * 0.075,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.star_rounded,
            size: scale * 0.05,
            color: accent,
          ),
        ),
      ],
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.folderName,
    required this.spotCount,
    required this.listsCount,
    required this.accent,
    required this.ink,
    required this.scale,
  });
  final String folderName;
  final int spotCount;
  final int listsCount;
  final Color accent;
  final Color ink;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: scale * 0.08,
          height: scale * 0.01,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(scale * 0.005),
          ),
        ),
        SizedBox(height: scale * 0.04),
        Text(
          folderName,
          maxLines: 3,
          style: TextStyle(
            fontSize: scale * 0.11,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: ink,
          ),
        ),
        SizedBox(height: scale * 0.04),
        Row(
          children: [
            _Stat(value: '$spotCount', label: 'spots', scale: scale, ink: ink),
            SizedBox(width: scale * 0.05),
            Container(
              width: 1,
              height: scale * 0.1,
              color: ink.withValues(alpha: 0.18),
            ),
            SizedBox(width: scale * 0.05),
            _Stat(
              value: '$listsCount',
              label: 'lists',
              scale: scale,
              ink: ink,
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            Icon(
              Icons.explore_outlined,
              size: scale * 0.045,
              color: ink.withValues(alpha: 0.4),
            ),
            SizedBox(width: scale * 0.018),
            Text(
              'polaris',
              style: TextStyle(
                fontSize: scale * 0.04,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: ink.withValues(alpha: 0.5),
              ),
            ),
            const Spacer(),
            Text(
              'おでかけメモアプリ',
              style: TextStyle(
                fontSize: scale * 0.028,
                color: ink.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.scale,
    required this.ink,
  });
  final String value;
  final String label;
  final double scale;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: scale * 0.08,
            fontWeight: FontWeight.w800,
            color: ink,
            letterSpacing: -0.3,
            height: 1,
          ),
        ),
        SizedBox(height: scale * 0.005),
        Text(
          label,
          style: TextStyle(
            fontSize: scale * 0.028,
            color: ink.withValues(alpha: 0.5),
            letterSpacing: 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
