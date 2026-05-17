import 'package:drift/drift.dart';
import 'package:polaris/core/db/app_database.dart';
import 'package:polaris/features/lists/models/spot_list.dart';

class ListsRepository {
  ListsRepository(this._db);
  final AppDatabase _db;

  Future<List<SpotList>> list() async {
    final query = _db.select(_db.lists)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<SpotList?> getById(String id) async {
    final query = _db.select(_db.lists)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull())
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<SpotList>> listByFolder(String folderId) async {
    final query = _db.select(_db.lists)
      ..where((t) => t.folderId.equals(folderId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<void> insert(SpotList l) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.lists).insert(
          ListsCompanion.insert(
            id: l.id,
            folderId: l.folderId,
            name: l.name,
            orderIndex: l.orderIndex,
            createdAt: ms,
            updatedAt: ms,
            iconName: Value(l.iconName),
            colorValue: Value(l.colorValue),
            coverPhotoUrl: Value(l.coverPhotoUrl),
            sortMode: Value(l.sortMode.name),
          ),
        );
  }

  Future<void> update(SpotList l) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.lists)..where((t) => t.id.equals(l.id))).write(
      ListsCompanion(
        folderId: Value(l.folderId),
        name: Value(l.name),
        iconName: Value(l.iconName),
        colorValue: Value(l.colorValue),
        coverPhotoUrl: Value(l.coverPhotoUrl),
        orderIndex: Value(l.orderIndex),
        sortMode: Value(l.sortMode.name),
        updatedAt: Value(ms),
      ),
    );
  }

  Future<void> softDelete(String id) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.lists)..where((t) => t.id.equals(id))).write(
      ListsCompanion(deletedAt: Value(ms), updatedAt: Value(ms)),
    );
  }

  SpotList _toDomain(SpotListRow r) {
    return SpotList(
      id: r.id,
      folderId: r.folderId,
      name: r.name,
      iconName: r.iconName,
      colorValue: r.colorValue,
      coverPhotoUrl: r.coverPhotoUrl,
      orderIndex: r.orderIndex,
      sortMode: SortMode.values.firstWhere(
        (m) => m.name == r.sortMode,
        orElse: () => SortMode.manual,
      ),
    );
  }
}

/// Spot ↔ List の中間テーブル操作。
class SpotListPairsRepository {
  SpotListPairsRepository(this._db);
  final AppDatabase _db;

  Future<List<({String spotId, String listId})>> listAll() async {
    final rows = await (_db.select(_db.spotLists)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return [
      for (final r in rows) (spotId: r.spotId, listId: r.listId),
    ];
  }

  Future<void> add(String spotId, String listId) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final maxOrder = await (_db.selectOnly(_db.spotLists)
          ..addColumns([_db.spotLists.orderIndex.max()])
          ..where(_db.spotLists.listId.equals(listId)))
        .map((r) => r.read(_db.spotLists.orderIndex.max()) ?? -1)
        .getSingle();
    await _db.into(_db.spotLists).insert(
          SpotListsCompanion.insert(
            id: 'sl-$ms-$spotId-$listId',
            spotId: spotId,
            listId: listId,
            orderIndex: maxOrder + 1,
            addedAt: ms,
            createdAt: ms,
            updatedAt: ms,
          ),
        );
  }

  Future<void> remove(String spotId, String listId) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.spotLists)
          ..where(
            (t) =>
                t.spotId.equals(spotId) &
                t.listId.equals(listId) &
                t.deletedAt.isNull(),
          ))
        .write(SpotListsCompanion(deletedAt: Value(ms), updatedAt: Value(ms)));
  }
}
