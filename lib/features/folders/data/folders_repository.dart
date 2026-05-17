import 'package:drift/drift.dart';
import 'package:polaris/core/db/app_database.dart';
import 'package:polaris/features/folders/models/folder.dart';

class FoldersRepository {
  FoldersRepository(this._db);
  final AppDatabase _db;

  Future<List<Folder>> list() async {
    final query = _db.select(_db.folders)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  Future<Folder?> getById(String id) async {
    final query = _db.select(_db.folders)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull())
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<void> insert(Folder f) async {
    final ms = f.updatedAt.millisecondsSinceEpoch;
    await _db
        .into(_db.folders)
        .insert(
          FoldersCompanion.insert(
            id: f.id,
            name: f.name,
            orderIndex: f.orderIndex,
            createdAt: ms,
            updatedAt: ms,
            iconName: Value(f.iconName),
            colorValue: Value(f.colorValue),
            coverPhotoUrl: Value(f.coverPhotoUrl),
          ),
        );
  }

  Future<void> update(Folder f) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.folders)..where((t) => t.id.equals(f.id))).write(
      FoldersCompanion(
        name: Value(f.name),
        iconName: Value(f.iconName),
        colorValue: Value(f.colorValue),
        coverPhotoUrl: Value(f.coverPhotoUrl),
        orderIndex: Value(f.orderIndex),
        updatedAt: Value(ms),
      ),
    );
  }

  Future<void> softDelete(String id) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.folders)..where((t) => t.id.equals(id))).write(
      FoldersCompanion(deletedAt: Value(ms), updatedAt: Value(ms)),
    );
  }

  Folder _toDomain(FolderRow r) {
    return Folder(
      id: r.id,
      name: r.name,
      iconName: r.iconName,
      colorValue: r.colorValue,
      coverPhotoUrl: r.coverPhotoUrl,
      orderIndex: r.orderIndex,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
    );
  }
}
