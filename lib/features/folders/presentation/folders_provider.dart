import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/db/database_provider.dart';
import 'package:polaris/features/folders/data/folders_repository.dart';
import 'package:polaris/features/folders/models/folder.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';

final foldersRepositoryProvider = Provider<FoldersRepository>((ref) {
  return FoldersRepository(ref.watch(databaseProvider));
});

class FoldersNotifier extends AsyncNotifier<List<Folder>> {
  @override
  Future<List<Folder>> build() async {
    final repo = ref.watch(foldersRepositoryProvider);
    return repo.list();
  }

  Future<void> create(Folder folder) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(foldersRepositoryProvider);
      await repo.insert(folder);
      return repo.list();
    });
  }

  Future<void> updateFolder(Folder folder) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(foldersRepositoryProvider);
      await repo.update(folder);
      return repo.list();
    });
  }

  Future<void> deleteFolder(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(foldersRepositoryProvider);
      await repo.softDelete(id);
      return repo.list();
    });
  }
}

final foldersNotifierProvider =
    AsyncNotifierProvider<FoldersNotifier, List<Folder>>(FoldersNotifier.new);

/// 既存のスクリーンが期待する `List` 同期インタフェース。
/// 初回ロード中は空配列を返す (mock データなので一瞬で埋まる)。
final foldersProvider = Provider<List<Folder>>((ref) {
  return ref.watch(foldersNotifierProvider).value ?? const [];
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
