import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:polaris/core/db/app_database.dart';
import 'package:polaris/features/visits/models/visit.dart';

class VisitsRepository {
  VisitsRepository(this._db);
  final AppDatabase _db;

  Future<List<Visit>> list() async {
    final query = _db.select(_db.visits)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.visitedAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Visit>> listBySpot(String spotId) async {
    final query = _db.select(_db.visits)
      ..where((t) => t.spotId.equals(spotId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.visitedAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<void> insert(Visit v) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.visits).insert(
          VisitsCompanion.insert(
            id: v.id,
            spotId: v.spotId,
            visitedAt: v.visitedAt.millisecondsSinceEpoch,
            createdAt: ms,
            updatedAt: ms,
            memo: Value(v.memo),
            rating: Value(v.rating),
            companions: Value(v.companions),
            costJpy: Value(v.costJpy),
            photoUrlsJson: Value(
              v.photoUrls.isEmpty ? null : jsonEncode(v.photoUrls),
            ),
          ),
        );
  }

  Future<void> update(Visit v) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.visits)..where((t) => t.id.equals(v.id))).write(
      VisitsCompanion(
        visitedAt: Value(v.visitedAt.millisecondsSinceEpoch),
        memo: Value(v.memo),
        rating: Value(v.rating),
        companions: Value(v.companions),
        costJpy: Value(v.costJpy),
        photoUrlsJson: Value(
          v.photoUrls.isEmpty ? null : jsonEncode(v.photoUrls),
        ),
        updatedAt: Value(ms),
      ),
    );
  }

  Future<void> softDelete(String id) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.visits)..where((t) => t.id.equals(id))).write(
      VisitsCompanion(deletedAt: Value(ms), updatedAt: Value(ms)),
    );
  }

  Visit _toDomain(VisitRow r) {
    return Visit(
      id: r.id,
      spotId: r.spotId,
      visitedAt: DateTime.fromMillisecondsSinceEpoch(r.visitedAt),
      memo: r.memo,
      rating: r.rating,
      companions: r.companions,
      costJpy: r.costJpy,
      photoUrls: r.photoUrlsJson == null
          ? const []
          : List<String>.from(jsonDecode(r.photoUrlsJson!) as List),
    );
  }
}
