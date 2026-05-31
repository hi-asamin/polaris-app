import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/sharing/widgets/folder_share_card.dart';
import 'package:polaris/features/sharing/widgets/share_card_preview.dart';

/// フォルダ用シェアカード画面。
class ShareCardScreen extends ConsumerWidget {
  const ShareCardScreen({required this.folderId, super.key});
  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folder = ref.watch(folderByIdProvider(folderId));
    final photos = ref.watch(folderCoverPhotosProvider(folderId));
    final spotCount = ref.watch(spotsCountByFolderProvider(folderId));
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
      body: ShareCardPreview(
        card: FolderShareCard(
          folder: folder,
          photos: photos,
          spotCount: spotCount,
          listsCount: 0,
        ),
        shareText: '${folder.name} - polaris で集めた行きたい場所',
        shareSubject: folder.name,
      ),
    );
  }
}
