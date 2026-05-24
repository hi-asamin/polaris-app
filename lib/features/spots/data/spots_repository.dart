import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:polaris/core/db/app_database.dart';
import 'package:polaris/core/network/places_api_client.dart';
import 'package:polaris/features/spots/models/spot.dart';

class SpotsRepository {
  SpotsRepository(this._db);
  final AppDatabase _db;

  Future<List<Spot>> list() async {
    final query = _db.select(_db.spots)..where((t) => t.deletedAt.isNull());
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

  Future<Spot?> getByPlaceId(String placeId) async {
    final query = _db.select(_db.spots)
      ..where((t) => t.placeId.equals(placeId) & t.deletedAt.isNull())
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<Spot>> listByListId(String listId) async {
    final spotIds =
        await (_db.select(_db.spotLists)
              ..where((t) => t.listId.equals(listId) & t.deletedAt.isNull()))
            .map((r) => r.spotId)
            .get();
    if (spotIds.isEmpty) return const [];
    final rows = await (_db.select(
      _db.spots,
    )..where((t) => t.id.isIn(spotIds) & t.deletedAt.isNull())).get();
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

  /// Places API のレスポンスでスポットを上書き更新。
  /// user_memo / want_to_visit / created_at などユーザー固有データは保持する。
  Future<void> applyPlaceDetails(String spotId, PlaceDetails details) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.spots)..where((t) => t.id.equals(spotId))).write(
      SpotsCompanion(
        name: details.name == null ? const Value.absent() : Value(details.name!),
        lat: details.lat == null ? const Value.absent() : Value(details.lat!),
        lng: details.lng == null ? const Value.absent() : Value(details.lng!),
        address: Value(details.formattedAddress),
        prefecture: Value(details.prefecture),
        city: Value(details.city),
        phoneNumber: Value(details.phoneNumber),
        websiteUrl: Value(details.websiteUri),
        openingHoursJson: Value(
          details.openingHours == null
              ? null
              : jsonEncode(details.openingHours),
        ),
        rating: Value(details.rating),
        ratingCount: Value(details.ratingCount),
        priceLevel: Value(details.priceLevel),
        editorialSummary: Value(details.editorialSummary),
        googleMapsUri: Value(details.googleMapsUri),
        placeTypesJson: Value(
          details.types.isEmpty ? null : jsonEncode(details.types),
        ),
        primaryCategory: Value(_inferCategory(details.types)),
        lastPlaceSyncedAt: Value(ms),
        updatedAt: Value(ms),
      ),
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
      editorialSummary: Value(s.editorialSummary),
      googleMapsUri: Value(s.googleMapsUri),
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
      editorialSummary: r.editorialSummary,
      googleMapsUri: r.googleMapsUri,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
      wantToVisit: r.wantToVisit,
    );
  }
}

/// Places API `types` から polaris カテゴリへの大まかなマッピング。
String _inferCategory(List<String> types) {
  for (final t in types) {
    if (_food.contains(t)) return 'food';
    if (_entertainment.contains(t)) return 'entertainment';
    if (_sightseeing.contains(t)) return 'sightseeing';
    if (_shopping.contains(t)) return 'shopping';
    if (_lodging.contains(t)) return 'lodging';
  }
  return 'other';
}

const _food = {
  'restaurant',
  'cafe',
  'bakery',
  'food',
  'meal_takeaway',
  'meal_delivery',
  'bar',
};
const _entertainment = {
  'amusement_park',
  'movie_theater',
  'bowling_alley',
  'casino',
  'night_club',
  'spa',
};
const _sightseeing = {
  'tourist_attraction',
  'museum',
  'art_gallery',
  'zoo',
  'aquarium',
  'park',
  'church',
  'place_of_worship',
  'library',
};
const _shopping = {
  'shopping_mall',
  'store',
  'clothing_store',
  'department_store',
  'supermarket',
  'book_store',
};
const _lodging = {'lodging'};
