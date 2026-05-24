import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide Cluster;
import 'package:polaris/features/spots/models/spot.dart';
import 'package:polaris/features/spots/models/spot_category_x.dart';

/// マップ上のピン (単独 / クラスタ) を描画するヘルパ群。
///
/// 純粋関数ではなく、内部で MediaQuery の devicePixelRatio を使うため
/// `BuildContext` を受け取る。
class SpotPinPainter {
  SpotPinPainter._();

  /// 単独スポットのピン (写真サムネ + カテゴリ色リング)。
  /// photoUrl が無いか読み込み失敗時はカテゴリアイコン入りの円にフォールバック。
  static Future<BitmapDescriptor> buildSpotPin({
    required BuildContext context,
    required Spot spot,
    required bool selected,
  }) async {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final color = spot.primaryCategory.color;
    final logicalSize = selected ? 68.0 : 56.0;
    final size = (logicalSize * ratio).round();
    final ringWidth = (selected ? 4 : 3) * ratio;
    final shadowBlur = (selected ? 8 : 4) * ratio;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final outerRadius = size / 2 - shadowBlur;

    // ドロップシャドウ
    canvas.drawCircle(
      center.translate(0, ratio),
      outerRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: selected ? 0.30 : 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur),
    );

    // 外側リング (カテゴリ色)
    canvas.drawCircle(center, outerRadius, Paint()..color = color);

    final innerRadius = outerRadius - ringWidth;
    final photoUrl = spot.photoUrls.isNotEmpty ? spot.photoUrls.first : null;
    final photo = photoUrl != null ? await _loadImage(photoUrl) : null;

    if (photo != null) {
      // 内側を円形クリップして写真を描く
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: innerRadius)),
      );
      final src = Rect.fromLTWH(
        0,
        0,
        photo.width.toDouble(),
        photo.height.toDouble(),
      );
      final dst = Rect.fromCircle(center: center, radius: innerRadius);
      canvas.drawImageRect(photo, src, dst, Paint());
      canvas.restore();
    } else {
      // フォールバック: カテゴリ色の中にアイコン
      canvas.drawCircle(center, innerRadius, Paint()..color = color);
      final icon = spot.primaryCategory.icon;
      final iconPainter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: innerRadius * 1.0,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: Colors.white,
          ),
        )
        ..layout();
      iconPainter.paint(
        canvas,
        Offset(
          center.dx - iconPainter.width / 2,
          center.dy - iconPainter.height / 2,
        ),
      );
    }

    final image = await recorder.endRecording().toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      imagePixelRatio: ratio,
    );
  }

  /// クラスタマーカー (count + ドミナントカテゴリ色)。
  static Future<BitmapDescriptor> buildClusterPin({
    required BuildContext context,
    required int count,
    required Color color,
    required bool selected,
  }) async {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final logicalSize = selected ? 64.0 : 56.0;
    final size = (logicalSize * ratio).round();
    final center = Offset(size / 2, size / 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 外側のソフトハロー
    canvas.drawCircle(
      center,
      size / 2,
      Paint()..color = color.withValues(alpha: selected ? 0.45 : 0.25),
    );
    // 本体
    canvas.drawCircle(center, size / 2.4, Paint()..color = color);
    // 白いリング
    canvas.drawCircle(
      center,
      size / 2.4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (selected ? 3.5 : 2.5) * ratio,
    );

    final painter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          fontSize: 16 * ratio,
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      )
      ..layout();
    painter.paint(
      canvas,
      Offset(
        center.dx - painter.width / 2,
        center.dy - painter.height / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      imagePixelRatio: ratio,
    );
  }

  /// クラスタ中の支配的カテゴリ。引き分けは要素順 (= primaryCategory enum 順) で
  /// 先勝ち。要素 0 のときは other。
  static SpotCategory dominantCategory(Iterable<Spot> spots) {
    if (spots.isEmpty) return SpotCategory.other;
    final counts = <SpotCategory, int>{};
    for (final s in spots) {
      counts.update(s.primaryCategory, (v) => v + 1, ifAbsent: () => 1);
    }
    var top = spots.first.primaryCategory;
    var topCount = counts[top]!;
    for (final entry in counts.entries) {
      if (entry.value > topCount) {
        top = entry.key;
        topCount = entry.value;
      }
    }
    return top;
  }
}

/// NetworkImage を ui.Image にデコードして返す。失敗時は null。
Future<ui.Image?> _loadImage(String url) async {
  try {
    final completer = Completer<ui.Image>();
    final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, _) {
        if (!completer.isCompleted) completer.completeError(error);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return await completer.future.timeout(const Duration(seconds: 8));
  } on Object {
    // 通信失敗・タイムアウト・画像デコード失敗いずれもピンの描画では
    // fallback 表示にしたいだけなので、種別を区別せず null で扱う。
    return null;
  }
}
