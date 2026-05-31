import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/db/database_provider.dart';
import 'package:polaris/core/db/system_entities.dart';
import 'package:polaris/features/folders/data/folders_repository.dart';
import 'package:polaris/features/folders/data/spot_folder_pairs_repository.dart';
import 'package:polaris/features/folders/models/folder.dart';
import 'package:polaris/features/spots/models/spot.dart';
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

/// Spot ↔ Folder の M:N ペア (新モデル)。
final spotFolderPairsRepositoryProvider =
    Provider<SpotFolderPairsRepository>((ref) {
      return SpotFolderPairsRepository(ref.watch(databaseProvider));
    });

class SpotFolderPairsNotifier
    extends AsyncNotifier<List<({String spotId, String folderId})>> {
  @override
  Future<List<({String spotId, String folderId})>> build() async {
    final repo = ref.watch(spotFolderPairsRepositoryProvider);
    return repo.listAll();
  }

  Future<void> add(String spotId, String folderId) async {
    final repo = ref.read(spotFolderPairsRepositoryProvider);
    await repo.add(spotId, folderId);
    state = AsyncData(await repo.listAll());
  }

  Future<void> remove(String spotId, String folderId) async {
    final repo = ref.read(spotFolderPairsRepositoryProvider);
    await repo.remove(spotId, folderId);
    state = AsyncData(await repo.listAll());
  }
}

final spotFolderPairsNotifierProvider =
    AsyncNotifierProvider<
      SpotFolderPairsNotifier,
      List<({String spotId, String folderId})>
    >(SpotFolderPairsNotifier.new);

final spotFolderPairsProvider =
    Provider<List<({String spotId, String folderId})>>((ref) {
      return ref.watch(spotFolderPairsNotifierProvider).value ?? const [];
    });

/// フォルダに所属するスポット一覧。
final spotsByFolderProvider = Provider.family<List<Spot>, String>((
  ref,
  folderId,
) {
  final pairs = ref.watch(spotFolderPairsProvider);
  final spotIds = pairs
      .where((p) => p.folderId == folderId)
      .map((p) => p.spotId)
      .toSet();
  final spots = ref.watch(allSpotsProvider);
  return spots.where((s) => spotIds.contains(s.id)).toList();
});

final spotsCountByFolderProvider = Provider.family<int, String>((ref, id) {
  return ref.watch(spotsByFolderProvider(id)).length;
});

/// 「行きたい」 = システム「行きたい」フォルダ所属。
final wantFolderSpotIdsProvider = Provider<Set<String>>((ref) {
  final pairs = ref.watch(spotFolderPairsProvider);
  return pairs
      .where((p) => p.folderId == SystemIds.wantFolderId)
      .map((p) => p.spotId)
      .toSet();
});

/// フォルダ配下のスポット写真を最大 N 件取得 (コラージュ用)。
final folderCoverPhotosProvider = Provider.family<List<String>, String>((
  ref,
  folderId,
) {
  final spots = ref.watch(spotsByFolderProvider(folderId));
  final photos = <String>[];
  final seen = <String>{};
  for (final s in spots) {
    if (s.photoUrls.isEmpty) continue;
    final url = s.photoUrls.first;
    if (seen.add(url)) photos.add(url);
    if (photos.length >= 3) break;
  }
  return photos;
});
