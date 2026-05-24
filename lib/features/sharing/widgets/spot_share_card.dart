import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:polaris/features/spots/models/spot.dart';

/// 単一スポット用 9:16 シェアカード。
/// `RepaintBoundary` で画像化される前提。
class SpotShareCard extends StatelessWidget {
  const SpotShareCard({
    required this.spot,
    required this.categoryLabel,
    required this.categoryColor,
    required this.categoryIcon,
    super.key,
  });

  final Spot spot;
  final String categoryLabel;
  final Color categoryColor;
  final IconData categoryIcon;

  String? get _personalLine {
    // ユーザーメモがあればそれを優先 (主役は「持ち主の声」)。
    if (spot.userMemo != null && spot.userMemo!.trim().isNotEmpty) {
      return spot.userMemo!.trim();
    }
    // なければ Google の editorial summary (あれば)。
    if (spot.editorialSummary != null &&
        spot.editorialSummary!.trim().isNotEmpty) {
      return spot.editorialSummary!.trim();
    }
    return null;
  }

  bool get _isFromUser =>
      spot.userMemo != null && spot.userMemo!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFBFAF7);
    const ink = Color(0xFF111418);
    final firstPhoto = spot.photoUrls.isNotEmpty ? spot.photoUrls.first : null;

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: bg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              children: [
                // 全画面のヒーロー写真。下半分はぼかしのグラデーションで暗く落とす。
                Positioned.fill(
                  child: firstPhoto == null
                      ? Container(
                          color: categoryColor.withValues(alpha: 0.2),
                          child: Center(
                            child: Icon(
                              categoryIcon,
                              size: w * 0.35,
                              color: categoryColor,
                            ),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: firstPhoto,
                          fit: BoxFit.cover,
                          placeholder: (c, _) =>
                              Container(color: categoryColor.withValues(alpha: 0.15)),
                          errorWidget: (c, _, _) => Container(
                            color: categoryColor.withValues(alpha: 0.15),
                            child: Center(
                              child: Icon(
                                categoryIcon,
                                size: w * 0.35,
                                color: categoryColor,
                              ),
                            ),
                          ),
                        ),
                ),
                // 下半分のテキスト可読性を上げる暗グラデ。
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        stops: const [0, 0.55, 1],
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ),
                // 上部の Curated チップ。
                Positioned(
                  top: w * 0.06,
                  left: w * 0.06,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.035,
                      vertical: w * 0.014,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(w * 0.06),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: w * 0.035,
                          color: categoryColor,
                        ),
                        SizedBox(width: w * 0.012),
                        Text(
                          'Curated on polaris',
                          style: TextStyle(
                            fontSize: w * 0.03,
                            fontWeight: FontWeight.w700,
                            color: ink.withValues(alpha: 0.75),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 下部のテキスト本体。
                Positioned(
                  left: w * 0.06,
                  right: w * 0.06,
                  bottom: w * 0.06,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MetaChips(
                        categoryLabel: categoryLabel,
                        categoryIcon: categoryIcon,
                        categoryColor: categoryColor,
                        rating: spot.rating,
                        priceLevel: spot.priceLevel,
                        scale: w,
                      ),
                      SizedBox(height: w * 0.04),
                      Text(
                        spot.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: w * 0.085,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.1,
                          color: Colors.white,
                          shadows: const [
                            Shadow(blurRadius: 12, color: Color(0x66000000)),
                          ],
                        ),
                      ),
                      if (spot.city != null || spot.prefecture != null) ...[
                        SizedBox(height: w * 0.015),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: w * 0.035,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            SizedBox(width: w * 0.012),
                            Flexible(
                              child: Text(
                                [spot.prefecture, spot.city]
                                    .where((e) => e != null && e.isNotEmpty)
                                    .join(' ・ '),
                                style: TextStyle(
                                  fontSize: w * 0.032,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_personalLine != null) ...[
                        SizedBox(height: w * 0.04),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.04,
                            vertical: w * 0.035,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(w * 0.04),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isFromUser ? 'メモ' : 'Google による説明',
                                style: TextStyle(
                                  fontSize: w * 0.024,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: categoryColor,
                                ),
                              ),
                              SizedBox(height: w * 0.008),
                              Text(
                                _personalLine!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: w * 0.034,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                  color: ink.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: w * 0.04),
                      Row(
                        children: [
                          Icon(
                            Icons.explore_outlined,
                            size: w * 0.04,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          SizedBox(width: w * 0.015),
                          Text(
                            'polaris で保存',
                            style: TextStyle(
                              fontSize: w * 0.034,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetaChips extends StatelessWidget {
  const _MetaChips({
    required this.categoryLabel,
    required this.categoryIcon,
    required this.categoryColor,
    required this.rating,
    required this.priceLevel,
    required this.scale,
  });
  final String categoryLabel;
  final IconData categoryIcon;
  final Color categoryColor;
  final double? rating;
  final int? priceLevel;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final w = scale;
    final items = <Widget>[
      _Chip(
        icon: categoryIcon,
        text: categoryLabel,
        bg: categoryColor,
        textColor: Colors.white,
        scale: w,
      ),
      if (rating != null)
        _Chip(
          icon: Icons.star_rounded,
          text: rating!.toStringAsFixed(1),
          bg: Colors.white,
          textColor: const Color(0xFF111418),
          iconColor: const Color(0xFFFFC107),
          scale: w,
        ),
      if (priceLevel != null)
        _Chip(
          text: '¥' * (priceLevel! + 1),
          bg: Colors.white.withValues(alpha: 0.9),
          textColor: const Color(0xFF111418),
          scale: w,
        ),
    ];
    return Wrap(
      spacing: w * 0.015,
      runSpacing: w * 0.015,
      children: items,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    required this.bg,
    required this.textColor,
    required this.scale,
    this.icon,
    this.iconColor,
  });
  final String text;
  final Color bg;
  final Color textColor;
  final IconData? icon;
  final Color? iconColor;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: scale * 0.025,
        vertical: scale * 0.01,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(scale * 0.04),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: scale * 0.032, color: iconColor ?? textColor),
            SizedBox(width: scale * 0.008),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: scale * 0.028,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
