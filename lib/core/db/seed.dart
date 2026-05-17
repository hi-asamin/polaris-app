import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:polaris/core/db/app_database.dart';
import 'package:polaris/core/mock/mock_data.dart';

/// 初回起動時にモックデータを DB に投入する。
/// すでに folder が 1 件でも入っていれば何もしない (デモ用)。
Future<void> seedIfEmpty(AppDatabase db) async {
  final existing = await (db.select(db.folders)..limit(1)).get();
  if (existing.isNotEmpty) return;

  await db.batch((batch) {
    final now = DateTime.now().millisecondsSinceEpoch;

    batch.insertAll(
      db.folders,
      [
        for (final f in MockData.folders)
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
        for (final l in MockData.lists)
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
        for (final s in MockData.spots)
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
        for (var i = 0; i < MockData.spotListPairs.length; i++)
          SpotListsCompanion.insert(
            id: 'spotlist-mock-$i',
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
        for (final v in MockData.visits)
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
