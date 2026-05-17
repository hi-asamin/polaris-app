import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:polaris/core/db/app_database.dart';
import 'package:polaris/features/spots/models/spot.dart';

class SpotsRepository {
  SpotsRepository(this._db);
  final AppDatabase _db;

  Future<List<Spot>> list() async {
    final query = _db.select(_db.spots)
      ..where((t) => t.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<Spot?> getById(String id) async {
    final query = _db.select(_db.spots)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull())
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<Spot>> listByListId(String listId) async {
    final spotIds = await (_db.select(_db.spotLists)
          ..where((t) => t.listId.equals(listId) & t.deletedAt.isNull()))
        .map((r) => r.spotId)
        .get();
    if (spotIds.isEmpty) return const [];
    final rows = await (_db.select(_db.spots)
          ..where((t) => t.id.isIn(spotIds) & t.deletedAt.isNull()))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<void> upsert(Spot s) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await _db
        .into(_db.spots)
        .insertOnConflictUpdate(_toCompanion(s, nowMs: ms));
  }

  Future<void> toggleWantToVisit(String id) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final current = await getById(id);
    if (current == null) return;
    await (_db.update(_db.spots)..where((t) => t.id.equals(id))).write(
      SpotsCompanion(
        wantToVisit: Value(!current.wantToVisit),
        updatedAt: Value(ms),
      ),
    );
  }

  Future<void> updateMemo(String id, String? memo) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.spots)..where((t) => t.id.equals(id))).write(
      SpotsCompanion(userMemo: Value(memo), updatedAt: Value(ms)),
    );
  }

  Future<void> softDelete(String id) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.spots)..where((t) => t.id.equals(id))).write(
      SpotsCompanion(deletedAt: Value(ms), updatedAt: Value(ms)),
    );
  }

  SpotsCompanion _toCompanion(Spot s, {required int nowMs}) {
    return SpotsCompanion.insert(
      id: s.id,
      placeId: s.placeId,
      name: s.name,
      lat: s.lat,
      lng: s.lng,
      lastPlaceSyncedAt: nowMs,
      createdAt: nowMs,
      updatedAt: nowMs,
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
    );
  }

  Spot _toDomain(SpotRow r) {
    return Spot(
      id: r.id,
      placeId: r.placeId,
      name: r.name,
      lat: r.lat,
      lng: r.lng,
      primaryCategory: SpotCategory.values.firstWhere(
        (c) => c.name == r.primaryCategory,
        orElse: () => SpotCategory.other,
      ),
      photoUrls: r.photoUrlsJson == null
          ? const []
          : List<String>.from(jsonDecode(r.photoUrlsJson!) as List),
      address: r.address,
      prefecture: r.prefecture,
      city: r.city,
      phoneNumber: r.phoneNumber,
      websiteUrl: r.websiteUrl,
      openingHours: r.openingHoursJson == null
          ? null
          : Map<String, String>.from(
              (jsonDecode(r.openingHoursJson!) as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ),
            ),
      rating: r.rating,
      ratingCount: r.ratingCount,
      priceLevel: r.priceLevel,
      userMemo: r.userMemo,
      wantToVisit: r.wantToVisit,
    );
  }
}
