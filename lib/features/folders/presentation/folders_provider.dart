import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/mock/mock_data.dart';
import 'package:polaris/features/folders/models/folder.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';

final foldersProvider = Provider<List<Folder>>((ref) {
  final list = [...MockData.folders]
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return list;
});

final folderByIdProvider = Provider.family<Folder?, String>((ref, id) {
  final folders = ref.watch(foldersProvider);
  for (final f in folders) {
    if (f.id == id) return f;
  }
  return null;
});

/// フォルダ配下のスポット写真を最大 N 件取得 (コラージュ用)。
final folderCoverPhotosProvider = Provider.family<List<String>, String>((
  ref,
  folderId,
) {
  final lists = ref.watch(listsByFolderProvider(folderId));
  final pairs = ref.watch(spotListPairsProvider);
  final spots = ref.watch(allSpotsProvider);

  final listIds = lists.map((l) => l.id).toSet();
  final spotIdsInFolder = <String>{};
  for (final p in pairs) {
    if (listIds.contains(p.listId)) spotIdsInFolder.add(p.spotId);
  }

  final photos = <String>[];
  final seen = <String>{};
  for (final s in spots) {
    if (!spotIdsInFolder.contains(s.id)) continue;
    if (s.photoUrls.isEmpty) continue;
    final url = s.photoUrls.first;
    if (seen.add(url)) photos.add(url);
    if (photos.length >= 3) break;
  }
  return photos;
});
