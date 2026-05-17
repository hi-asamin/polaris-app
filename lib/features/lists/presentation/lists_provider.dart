import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/mock/mock_data.dart';
import 'package:polaris/features/lists/models/spot_list.dart';
import 'package:polaris/features/spots/models/spot.dart';

final listsProvider = Provider<List<SpotList>>((ref) {
  final list = [...MockData.lists]
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return list;
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

final spotListPairsProvider = Provider<List<({String spotId, String listId})>>((
  ref,
) {
  return MockData.spotListPairs;
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

/// リスト配下のスポット写真を最大 N 件取得 (コラージュ用)。
/// 直接 spots を参照すると `spots_provider` に循環依存するので、
/// 呼び出し側で `allSpotsProvider` を渡してもらう想定だが、
/// 簡潔さのため `MockData.spots` を直接読む (モック前提)。
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
