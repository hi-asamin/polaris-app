import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:polaris/core/db/app_database.dart';
import 'package:polaris/core/mock/mock_data.dart';

/// オンボーディングで選べるサンプルデータセット。
enum SampleSet {
  tokyo('tokyo'),
  kyoto('kyoto'),
  none('none');

  const SampleSet(this.key);
  final String key;

  static SampleSet? fromKey(String? key) {
    if (key == null) return null;
    for (final v in SampleSet.values) {
      if (v.key == key) return v;
    }
    return null;
  }
}

/// 選択されたサンプルセットに応じて DB に初期データを投入する。
///
/// [set] が [SampleSet.none] の場合は何もしない。既存データがある場合 (= 過去
/// オンボーディング済みで再実行された場合) はそのまま追加挿入してしまうため、
/// 呼び出し側で「初回のみ」を保証すること。
Future<void> loadSample(AppDatabase db, SampleSet set) async {
  if (set == SampleSet.none) return;

  final folderIds = _folderIdsFor(set);
  if (folderIds.isEmpty) return;

  final folders = MockData.folders.where((f) => folderIds.contains(f.id)).toList();
  final lists = MockData.lists.where((l) => folderIds.contains(l.folderId)).toList();
  final listIds = lists.map((l) => l.id).toSet();

  // どのスポットを取り込むかは spotListPairs から逆引きする
  // (= 選択フォルダ配下のリストに 1 つでも含まれているスポット)。
  final pairIndices = <int>[];
  final keepSpotIds = <String>{};
  for (var i = 0; i < MockData.spotListPairs.length; i++) {
    final pair = MockData.spotListPairs[i];
    if (!listIds.contains(pair.listId)) continue;
    pairIndices.add(i);
    keepSpotIds.add(pair.spotId);
  }
  final spots = MockData.spots.where((s) => keepSpotIds.contains(s.id)).toList();
  final visits =
      MockData.visits.where((v) => keepSpotIds.contains(v.spotId)).toList();

  await db.batch((batch) {
    final now = DateTime.now().millisecondsSinceEpoch;

    batch.insertAll(
      db.folders,
      [
        for (final f in folders)
          FoldersCompanion.insert(
            id: f.id,
            name: f.name,
            orderIndex: f.orderIndex,
            createdAt: f.updatedAt.millisecondsSinceEpoch,
            updatedAt: f.updatedAt.millisecondsSinceEpoch,
            iconName: Value(f.iconName),
            colorValue: Value(f.colorValue),
            coverPhotoUrl: Value(f.coverPhotoUrl),
          ),
      ],
    );

    batch.insertAll(
      db.lists,
      [
        for (final l in lists)
          ListsCompanion.insert(
            id: l.id,
            folderId: l.folderId,
            name: l.name,
            orderIndex: l.orderIndex,
            createdAt: now,
            updatedAt: now,
            iconName: Value(l.iconName),
            colorValue: Value(l.colorValue),
            coverPhotoUrl: Value(l.coverPhotoUrl),
            sortMode: Value(l.sortMode.name),
          ),
      ],
    );

    batch.insertAll(
      db.spots,
      [
        for (final s in spots)
          SpotsCompanion.insert(
            id: s.id,
            placeId: s.placeId,
            name: s.name,
            lat: s.lat,
            lng: s.lng,
            lastPlaceSyncedAt: now,
            createdAt: now,
            updatedAt: now,
            primaryCategory: Value(s.primaryCategory.name),
            photoUrlsJson: Value(
              s.photoUrls.isEmpty ? null : jsonEncode(s.photoUrls),
            ),
            address: Value(s.address),
            prefecture: Value(s.prefecture),
            city: Value(s.city),
            phoneNumber: Value(s.phoneNumber),
            websiteUrl: Value(s.websiteUrl),
            openingHoursJson: Value(
              s.openingHours == null ? null : jsonEncode(s.openingHours),
            ),
            rating: Value(s.rating),
            ratingCount: Value(s.ratingCount),
            priceLevel: Value(s.priceLevel),
            userMemo: Value(s.userMemo),
            wantToVisit: Value(s.wantToVisit),
          ),
      ],
    );

    batch.insertAll(
      db.spotLists,
      [
        for (final i in pairIndices)
          SpotListsCompanion.insert(
            id: 'spotlist-sample-${set.key}-$i',
            spotId: MockData.spotListPairs[i].spotId,
            listId: MockData.spotListPairs[i].listId,
            orderIndex: i,
            addedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
      ],
    );

    batch.insertAll(
      db.visits,
      [
        for (final v in visits)
          VisitsCompanion.insert(
            id: v.id,
            spotId: v.spotId,
            visitedAt: v.visitedAt.millisecondsSinceEpoch,
            createdAt: now,
            updatedAt: now,
            memo: Value(v.memo),
            rating: Value(v.rating),
            companions: Value(v.companions),
            costJpy: Value(v.costJpy),
            photoUrlsJson: Value(
              v.photoUrls.isEmpty ? null : jsonEncode(v.photoUrls),
            ),
          ),
      ],
    );
  });
}

Set<String> _folderIdsFor(SampleSet set) {
  switch (set) {
    case SampleSet.tokyo:
      // 東京 + デート候補 (どちらも首都圏なのでセットで入れる)
      return {'folder-tokyo', 'folder-date'};
    case SampleSet.kyoto:
      return {'folder-kyoto'};
    case SampleSet.none:
      return const {};
  }
}
