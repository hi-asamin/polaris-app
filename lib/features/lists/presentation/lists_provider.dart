import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/db/database_provider.dart';
import 'package:polaris/core/mock/mock_data.dart';
import 'package:polaris/features/lists/data/lists_repository.dart';
import 'package:polaris/features/lists/models/spot_list.dart';
import 'package:polaris/features/spots/models/spot.dart';

final listsRepositoryProvider = Provider<ListsRepository>((ref) {
  return ListsRepository(ref.watch(databaseProvider));
});

final spotListPairsRepositoryProvider = Provider<SpotListPairsRepository>((
  ref,
) {
  return SpotListPairsRepository(ref.watch(databaseProvider));
});

class ListsNotifier extends AsyncNotifier<List<SpotList>> {
  @override
  Future<List<SpotList>> build() async {
    final repo = ref.watch(listsRepositoryProvider);
    return repo.list();
  }

  Future<void> create(SpotList l) async {
    final repo = ref.read(listsRepositoryProvider);
    await repo.insert(l);
    state = AsyncData(await repo.list());
  }

  Future<void> updateList(SpotList l) async {
    final repo = ref.read(listsRepositoryProvider);
    await repo.update(l);
    state = AsyncData(await repo.list());
  }

  Future<void> deleteList(String id) async {
    final repo = ref.read(listsRepositoryProvider);
    await repo.softDelete(id);
    state = AsyncData(await repo.list());
  }
}

final listsNotifierProvider =
    AsyncNotifierProvider<ListsNotifier, List<SpotList>>(ListsNotifier.new);

final listsProvider = Provider<List<SpotList>>((ref) {
  return ref.watch(listsNotifierProvider).value ?? const [];
});

final listsByFolderProvider = Provider.family<List<SpotList>, String>((
  ref,
  folderId,
) {
  return ref.watch(listsProvider).where((l) => l.folderId == folderId).toList();
});

final listByIdProvider = Provider.family<SpotList?, String>((ref, id) {
  for (final l in ref.watch(listsProvider)) {
    if (l.id == id) return l;
  }
  return null;
});

/// 中間テーブル (Spot ↔ List) も AsyncNotifier で DB-backed に。
class SpotListPairsNotifier
    extends AsyncNotifier<List<({String spotId, String listId})>> {
  @override
  Future<List<({String spotId, String listId})>> build() async {
    final repo = ref.watch(spotListPairsRepositoryProvider);
    return repo.listAll();
  }

  Future<void> add(String spotId, String listId) async {
    final repo = ref.read(spotListPairsRepositoryProvider);
    await repo.add(spotId, listId);
    state = AsyncData(await repo.listAll());
  }

  Future<void> remove(String spotId, String listId) async {
    final repo = ref.read(spotListPairsRepositoryProvider);
    await repo.remove(spotId, listId);
    state = AsyncData(await repo.listAll());
  }
}

final spotListPairsNotifierProvider =
    AsyncNotifierProvider<
      SpotListPairsNotifier,
      List<({String spotId, String listId})>
    >(SpotListPairsNotifier.new);

final spotListPairsProvider = Provider<List<({String spotId, String listId})>>((
  ref,
) {
  return ref.watch(spotListPairsNotifierProvider).value ?? const [];
});

final spotsCountByListProvider = Provider.family<int, String>((ref, listId) {
  final pairs = ref.watch(spotListPairsProvider);
  return pairs.where((p) => p.listId == listId).length;
});

final spotsCountByFolderProvider = Provider.family<int, String>((
  ref,
  folderId,
) {
  final lists = ref.watch(listsByFolderProvider(folderId));
  final pairs = ref.watch(spotListPairsProvider);
  final listIds = lists.map((l) => l.id).toSet();
  return pairs.where((p) => listIds.contains(p.listId)).length;
});

/// リスト配下のスポット写真を最大 3 件取得 (コラージュ用)。
/// FIXME: 現状は `MockData.spots` を直接読んでいる暫定実装。
/// spots feature の AsyncNotifier 経由に切り替える必要があるが、
/// プロバイダ間の循環を避けるためファイル分割の整理が必要。
final listCoverPhotosProvider = Provider.family<List<String>, String>((
  ref,
  listId,
) {
  final pairs = ref.watch(spotListPairsProvider);
  final spotIds = pairs
      .where((p) => p.listId == listId)
      .map((p) => p.spotId)
      .toSet();

  final byId = <String, Spot>{for (final s in MockData.spots) s.id: s};
  final photos = <String>[];
  final seen = <String>{};
  for (final spotId in spotIds) {
    final s = byId[spotId];
    if (s == null || s.photoUrls.isEmpty) continue;
    final url = s.photoUrls.first;
    if (seen.add(url)) photos.add(url);
    if (photos.length >= 3) break;
  }
  return photos;
});
