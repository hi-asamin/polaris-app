import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/mock/mock_data.dart';
import 'package:polaris/features/lists/models/spot_list.dart';

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
