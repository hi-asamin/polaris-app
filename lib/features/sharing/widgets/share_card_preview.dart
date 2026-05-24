import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 9:16 のシェアカードを浮かせて表示し、ボトムにシェアボタンを置く共通 UI。
/// card には `AspectRatio(9/16, child: ...)` を含む widget を渡すこと。
class ShareCardPreview extends StatefulWidget {
  const ShareCardPreview({
    required this.card,
    required this.shareText,
    required this.shareSubject,
    super.key,
  });

  final Widget card;
  final String shareText;
  final String shareSubject;

  @override
  State<ShareCardPreview> createState() => _ShareCardPreviewState();
}

class _ShareCardPreviewState extends State<ShareCardPreview> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  Future<XFile> _renderToFile() async {
    await SchedulerBinding.instance.endOfFrame;
    final boundary =
        _boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final path = p.join(
      dir.path,
      'polaris_share_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    final file = File(path);
    await file.writeAsBytes(bytes);
    return XFile(file.path, mimeType: 'image/png', name: 'polaris_share.png');
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _renderToFile();
      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          text: widget.shareText,
          subject: widget.shareSubject,
        ),
      );
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('シェアに失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              child: PhysicalModel(
                color: Colors.transparent,
                elevation: 12,
                shadowColor: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: widget.card,
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton.icon(
              onPressed: _busy ? null : _share,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_rounded),
              label: const Text('シェア'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
