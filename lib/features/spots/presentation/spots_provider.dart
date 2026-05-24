import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/db/database_provider.dart';
import 'package:polaris/core/network/places_api_client.dart';
import 'package:polaris/core/network/places_api_provider.dart';
import 'package:polaris/core/utils/id.dart';
import 'package:polaris/features/discover/data/curation_mock.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/features/spots/data/spots_repository.dart';
import 'package:polaris/features/spots/models/spot.dart';

final spotsRepositoryProvider = Provider<SpotsRepository>((ref) {
  return SpotsRepository(ref.watch(databaseProvider));
});

class SpotsNotifier extends AsyncNotifier<List<Spot>> {
  @override
  Future<List<Spot>> build() async {
    final repo = ref.watch(spotsRepositoryProvider);
    return repo.list();
  }

  Future<void> toggleWantToVisit(String spotId) async {
    final repo = ref.read(spotsRepositoryProvider);
    await repo.toggleWantToVisit(spotId);
    state = AsyncData(await repo.list());
  }

  Future<void> updateMemo(String spotId, String? memo) async {
    final repo = ref.read(spotsRepositoryProvider);
    await repo.updateMemo(spotId, memo);
    state = AsyncData(await repo.list());
  }

  /// Places API から最新詳細を取得して上書き。
  /// API キーが未設定 / Place ID が無効 / 通信エラーは [Exception] を throw する。
  Future<void> refreshFromPlaces(String spotId) async {
    final client = ref.read(placesApiClientProvider);
    if (client == null) {
      throw Exception('Places API key is not configured');
    }
    final repo = ref.read(spotsRepositoryProvider);
    final spot = await repo.getById(spotId);
    if (spot == null) throw Exception('Spot not found');

    final details = await client.details(spot.placeId);
    await repo.applyPlaceDetails(spotId, details);
    state = AsyncData(await repo.list());
  }

  /// キュレーションスポット (静的データ) を DB に保存。
  /// 既存 placeId なら既存 Spot.id を返す。新規なら最低限の情報で insert。
  /// モック期は Place ID がダミーなので details 取得は試みない。
  Future<String> saveFromCurationSpot(CurationSpot spot) async {
    final repo = ref.read(spotsRepositoryProvider);
    final existing = await repo.getByPlaceId(spot.placeId);
    if (existing != null) return existing.id;

    final id = newId();
    final newSpot = Spot(
      id: id,
      placeId: spot.placeId,
      name: spot.name,
      lat: spot.lat,
      lng: spot.lng,
      address: spot.address,
      rating: spot.rating,
      photoUrls: spot.photoUrls,
      userMemo: spot.editorialNote,
    );
    await repo.upsert(newSpot);
    state = AsyncData(await repo.list());
    return id;
  }

  /// Places 検索結果から新規スポットを DB に保存。
  /// 既存 placeId なら何もせず、既存 Spot の id を返す。
  /// 新規の場合は最低限のフィールドで insert → details 取得で上書き。
  Future<String> saveFromPlace(PlaceSearchResult result) async {
    final repo = ref.read(spotsRepositoryProvider);
    final existing = await repo.getByPlaceId(result.placeId);
    if (existing != null) return existing.id;

    final id = newId();
    final newSpot = Spot(
      id: id,
      placeId: result.placeId,
      name: result.name,
      lat: result.lat,
      lng: result.lng,
      address: result.formattedAddress,
      rating: result.rating,
      ratingCount: result.ratingCount,
    );
    await repo.upsert(newSpot);

    // 取得できれば詳細で上書き (失敗してもスポット自体は残す)。
    final client = ref.read(placesApiClientProvider);
    if (client != null) {
      try {
        final details = await client.details(result.placeId);
        await repo.applyPlaceDetails(id, details);
      } on Exception {
        // 通信失敗は無視。基本情報だけで保存される。
      }
    }

    state = AsyncData(await repo.list());
    return id;
  }
}

final spotsNotifierProvider = AsyncNotifierProvider<SpotsNotifier, List<Spot>>(
  SpotsNotifier.new,
);

final allSpotsProvider = Provider<List<Spot>>((ref) {
  return ref.watch(spotsNotifierProvider).value ?? const [];
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
