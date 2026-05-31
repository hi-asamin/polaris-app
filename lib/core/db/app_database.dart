import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:polaris/core/db/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Folders, Lists, Spots, SpotLists, SpotFolders, Visits, UserProfiles],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(spots, spots.editorialSummary);
        await m.addColumn(spots, spots.googleMapsUri);
      }
      if (from < 3) {
        await m.createTable(userProfiles);
      }
      if (from < 4) {
        await m.addColumn(spots, spots.isFavorite);
      }
      if (from < 5) {
        await m.createTable(spotFolders);
        // 既存の spot_lists を spot_folders に変換 (List.folderId 経由)。
        // 同一 (spotId, folderId) は uniqueKey で 1 行に集約される。
        await customStatement('''
          INSERT OR IGNORE INTO spot_folders
            (id, spot_id, folder_id, order_index, added_at, created_at, updated_at)
          SELECT
            'spotfolder-migrated-' || sl.id,
            sl.spot_id,
            l.folder_id,
            sl.order_index,
            sl.added_at,
            sl.created_at,
            sl.updated_at
          FROM spot_lists sl
          INNER JOIN lists l ON l.id = sl.list_id
          WHERE sl.deleted_at IS NULL AND l.deleted_at IS NULL;
        ''');
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'polaris.db'));
    return NativeDatabase.createInBackground(file);
  });
}
