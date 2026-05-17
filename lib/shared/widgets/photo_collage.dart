import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 1〜4 枚の写真で Pinterest 風コラージュを描画。
/// 各セルは `BoxFit.cover` で枠を必ず埋め、画像のアスペクト比に
/// 関わらずトリミングして表示する。写真がない場合は fallback の単色 + 任意アイコンを表示。
class PhotoCollage extends StatelessWidget {
  const PhotoCollage({
    required this.photos,
    this.fallbackColor,
    this.fallbackIcon,
    this.gap = 2,
    super.key,
  });

  final List<String> photos;
  final Color? fallbackColor;
  final IconData? fallbackIcon;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = fallbackColor ?? scheme.surfaceContainerHighest;

    if (photos.isEmpty) {
      return ColoredBox(
        color: bg,
        child: fallbackIcon != null
            ? Center(
                child: Icon(
                  fallbackIcon,
                  color: scheme.onSurfaceVariant,
                  size: 40,
                ),
              )
            : const SizedBox.expand(),
      );
    }
    if (photos.length == 1) {
      return _Photo(url: photos[0], bg: bg);
    }
    if (photos.length == 2) {
      return Row(
        children: [
          Expanded(child: _Photo(url: photos[0], bg: bg)),
          SizedBox(width: gap),
          Expanded(child: _Photo(url: photos[1], bg: bg)),
        ],
      );
    }
    if (photos.length == 3) {
      return Row(
        children: [
          Expanded(flex: 2, child: _Photo(url: photos[0], bg: bg)),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _Photo(url: photos[1], bg: bg)),
                SizedBox(height: gap),
                Expanded(child: _Photo(url: photos[2], bg: bg)),
              ],
            ),
          ),
        ],
      );
    }
    // 4+
    return Row(
      children: [
        Expanded(flex: 2, child: _Photo(url: photos[0], bg: bg)),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _Photo(url: photos[1], bg: bg)),
              SizedBox(height: gap),
              Expanded(child: _Photo(url: photos[2], bg: bg)),
              SizedBox(height: gap),
              Expanded(child: _Photo(url: photos[3], bg: bg)),
            ],
          ),
        ),
      ],
    );
  }
}

/// 親の制約に必ず一致するサイズで画像を center-crop 表示する。
/// `DecorationImage` は枠より大きい画像でも小さい画像でも `BoxFit.cover` で枠を埋める。
class _Photo extends StatelessWidget {
  const _Photo({required this.url, required this.bg});
  final String url;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        image: DecorationImage(
          image: CachedNetworkImageProvider(url),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
