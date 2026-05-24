import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/features/sharing/widgets/folder_share_card.dart';
import 'package:share_plus/share_plus.dart';

class ShareCardScreen extends ConsumerStatefulWidget {
  const ShareCardScreen({required this.folderId, super.key});
  final String folderId;

  @override
  ConsumerState<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends ConsumerState<ShareCardScreen> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  Future<XFile> _renderToFile() async {
    // 直近のフレームが完全に paint されるのを待つ。
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

  Future<void> _share(String folderName) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _renderToFile();
      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          text: '$folderName - polaris で集めた行きたい場所',
          subject: folderName,
        ),
      );
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('シェアに失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final folder = ref.watch(folderByIdProvider(widget.folderId));
    final photos = ref.watch(folderCoverPhotosProvider(widget.folderId));
    final spotCount = ref.watch(spotsCountByFolderProvider(widget.folderId));
    final lists = ref.watch(listsByFolderProvider(widget.folderId));
    final scheme = Theme.of(context).colorScheme;

    if (folder == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Folder not found')),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('シェア'),
        backgroundColor: scheme.surfaceContainerLowest,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: PhysicalModel(
                    color: Colors.transparent,
                    elevation: 12,
                    shadowColor: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(24),
                    clipBehavior: Clip.antiAlias,
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: FolderShareCard(
                        folder: folder,
                        photos: photos,
                        spotCount: spotCount,
                        listsCount: lists.length,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _share(folder.name),
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.ios_share_rounded),
                      label: const Text('シェア'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
