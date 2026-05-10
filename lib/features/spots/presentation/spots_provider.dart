import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/mock/mock_data.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/features/spots/models/spot.dart';

class SpotsNotifier extends Notifier<List<Spot>> {
  @override
  List<Spot> build() {
    return [...MockData.spots];
  }

  void toggleWantToVisit(String spotId) {
    state = [
      for (final s in state)
        if (s.id == spotId) s.copyWith(wantToVisit: !s.wantToVisit) else s,
    ];
  }

  void updateMemo(String spotId, String? memo) {
    state = [
      for (final s in state)
        if (s.id == spotId) s.copyWith(userMemo: memo) else s,
    ];
  }
}

final spotsNotifierProvider = NotifierProvider<SpotsNotifier, List<Spot>>(
  SpotsNotifier.new,
);

final allSpotsProvider = Provider<List<Spot>>((ref) {
  return ref.watch(spotsNotifierProvider);
});

final spotByIdProvider = Provider.family<Spot?, String>((ref, id) {
  for (final s in ref.watch(allSpotsProvider)) {
    if (s.id == id) return s;
  }
  return null;
});

final spotsByListProvider = Provider.family<List<Spot>, String>((ref, listId) {
  final pairs = ref.watch(spotListPairsProvider);
  final spots = ref.watch(allSpotsProvider);
  final spotIds = pairs
      .where((p) => p.listId == listId)
      .map((p) => p.spotId)
      .toSet();
  return spots.where((s) => spotIds.contains(s.id)).toList();
});

final wantToVisitSpotsProvider = Provider<List<Spot>>((ref) {
  return ref.watch(allSpotsProvider).where((s) => s.wantToVisit).toList();
});

class SpotFilter {
  const SpotFilter({
    this.categories = const {},
    this.listIds = const {},
    this.prefectures = const {},
    this.visitState = VisitFilterState.all,
  });

  final Set<SpotCategory> categories;
  final Set<String> listIds;
  final Set<String> prefectures;
  final VisitFilterState visitState;

  SpotFilter copyWith({
    Set<SpotCategory>? categories,
    Set<String>? listIds,
    Set<String>? prefectures,
    VisitFilterState? visitState,
  }) {
    return SpotFilter(
      categories: categories ?? this.categories,
      listIds: listIds ?? this.listIds,
      prefectures: prefectures ?? this.prefectures,
      visitState: visitState ?? this.visitState,
    );
  }

  bool get isEmpty =>
      categories.isEmpty &&
      listIds.isEmpty &&
      prefectures.isEmpty &&
      visitState == VisitFilterState.all;
}

enum VisitFilterState { all, visited, notVisited, wantToVisit }

class SpotFilterNotifier extends Notifier<SpotFilter> {
  @override
  SpotFilter build() => const SpotFilter();

  void toggleCategory(SpotCategory c) {
    final next = {...state.categories};
    if (!next.add(c)) next.remove(c);
    state = state.copyWith(categories: next);
  }

  void toggleList(String listId) {
    final next = {...state.listIds};
    if (!next.add(listId)) next.remove(listId);
    state = state.copyWith(listIds: next);
  }

  void togglePrefecture(String prefecture) {
    final next = {...state.prefectures};
    if (!next.add(prefecture)) next.remove(prefecture);
    state = state.copyWith(prefectures: next);
  }

  void setVisitState(VisitFilterState v) {
    state = state.copyWith(visitState: v);
  }

  void reset() {
    state = const SpotFilter();
  }
}

final spotFilterProvider = NotifierProvider<SpotFilterNotifier, SpotFilter>(
  SpotFilterNotifier.new,
);

final filteredSpotsProvider = Provider<List<Spot>>((ref) {
  final spots = ref.watch(allSpotsProvider);
  final filter = ref.watch(spotFilterProvider);
  final pairs = ref.watch(spotListPairsProvider);

  if (filter.isEmpty) return spots;

  final allowedSpotIdsByList = filter.listIds.isEmpty
      ? null
      : pairs
            .where((p) => filter.listIds.contains(p.listId))
            .map((p) => p.spotId)
            .toSet();

  return spots.where((s) {
    if (filter.categories.isNotEmpty &&
        !filter.categories.contains(s.primaryCategory)) {
      return false;
    }
    if (filter.prefectures.isNotEmpty &&
        (s.prefecture == null || !filter.prefectures.contains(s.prefecture))) {
      return false;
    }
    if (allowedSpotIdsByList != null && !allowedSpotIdsByList.contains(s.id)) {
      return false;
    }
    return true;
  }).toList();
});
