import 'package:drift/drift.dart';
import 'package:polaris/core/db/app_database.dart';

/// Spot ↔ Folder の M:N 中間テーブル操作。
/// 1 階層フォルダ構造に移行後の正本。リポジトリ API は List 版と同形。
class SpotFolderPairsRepository {
  SpotFolderPairsRepository(this._db);
  final AppDatabase _db;

  Future<List<({String spotId, String folderId})>> listAll() async {
    final rows = await (_db.select(
      _db.spotFolders,
    )..where((t) => t.deletedAt.isNull())).get();
    return [
      for (final r in rows) (spotId: r.spotId, folderId: r.folderId),
    ];
  }

  Future<void> add(String spotId, String folderId) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    // 既に同一ペアが (生きた状態で) 存在するなら no-op。
    // soft delete 済みなら復活させる。
    final existing = await (_db.select(_db.spotFolders)
          ..where(
            (t) =>
                t.spotId.equals(spotId) &
                t.folderId.equals(folderId),
          )
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      if (existing.deletedAt == null) return;
      await (_db.update(_db.spotFolders)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        SpotFoldersCompanion(
          deletedAt: const Value(null),
          updatedAt: Value(ms),
        ),
      );
      return;
    }
    final maxOrder =
        await (_db.selectOnly(_db.spotFolders)
              ..addColumns([_db.spotFolders.orderIndex.max()])
              ..where(_db.spotFolders.folderId.equals(folderId)))
            .map((r) => r.read(_db.spotFolders.orderIndex.max()) ?? -1)
            .getSingle();
    await _db
        .into(_db.spotFolders)
        .insert(
          SpotFoldersCompanion.insert(
            id: 'sf-$ms-$spotId-$folderId',
            spotId: spotId,
            folderId: folderId,
            orderIndex: maxOrder + 1,
            addedAt: ms,
            createdAt: ms,
            updatedAt: ms,
          ),
        );
  }

  Future<void> remove(String spotId, String folderId) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.spotFolders)..where(
          (t) =>
              t.spotId.equals(spotId) &
              t.folderId.equals(folderId) &
              t.deletedAt.isNull(),
        ))
        .write(SpotFoldersCompanion(deletedAt: Value(ms), updatedAt: Value(ms)));
  }
}
