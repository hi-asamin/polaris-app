import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 1〜4 枚の写真で Pinterest 風コラージュを描画。
/// 写真がない場合は fallback の単色を表示する。
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
      return Container(
        color: bg,
        alignment: Alignment.center,
        child: fallbackIcon != null
            ? Icon(fallbackIcon, color: scheme.onSurfaceVariant, size: 40)
            : null,
      );
    }
    if (photos.length == 1) {
      return _Photo(url: photos[0], bg: bg);
    }
    if (photos.length == 2) {
      return Row(
        children: [
          Expanded(
            child: _Photo(url: photos[0], bg: bg),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _Photo(url: photos[1], bg: bg),
          ),
        ],
      );
    }
    if (photos.length == 3) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: _Photo(url: photos[0], bg: bg),
          ),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _Photo(url: photos[1], bg: bg),
                ),
                SizedBox(height: gap),
                Expanded(
                  child: _Photo(url: photos[2], bg: bg),
                ),
              ],
            ),
          ),
        ],
      );
    }
    // 4 +
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _Photo(url: photos[0], bg: bg),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _Photo(url: photos[1], bg: bg),
              ),
              SizedBox(height: gap),
              Expanded(
                child: _Photo(url: photos[2], bg: bg),
              ),
              SizedBox(height: gap),
              Expanded(
                child: _Photo(url: photos[3], bg: bg),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url, required this.bg});
  final String url;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (c, _) => Container(color: bg),
      errorWidget: (c, _, _) => Container(color: bg),
    );
  }
}
