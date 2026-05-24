import 'package:drift/drift.dart';
import 'package:polaris/core/db/app_database.dart';

/// システム所属のフォルダ・リストの固定 ID。これらは削除不可。
class SystemIds {
  SystemIds._();

  /// デフォルトフォルダ「保存スポット」。「行きたい」リスト等の
  /// システムリストがここに所属する。
  static const String defaultFolderId = 'folder-system-default';

  /// 「行きたい」システムリスト。保存時にデフォルトでチェックされ、
  /// 訪問時に自動で外れる。ユーザーは手動 add/remove 可能。
  static const String wantListId = 'list-system-want';

  static const Set<String> protectedFolderIds = {defaultFolderId};
  static const Set<String> protectedListIds = {wantListId};
}

/// アプリ起動時にシステムリストを初期化する。
///
/// オンボーディング完了済み (= UserProfile が存在する) ユーザーに対して呼ぶ。
/// 何度呼んでも副作用が増えない idempotent な実装。
///
/// 初回実行 (= 既存ユーザー / 新規ユーザー どちらも):
/// 1. デフォルトフォルダが無ければ作る
/// 2. 「行きたい」リストが無ければ作る
/// 3. spots.wantToVisit = true かつ未訪問のスポットを「行きたい」リストに
///    バックフィル (旧 wantToVisit フラグからの移行用、1 度きり)
Future<void> ensureSystemListsExist(AppDatabase db) async {
  final now = DateTime.now().millisecondsSinceEpoch;

  // 1. デフォルトフォルダ
  final existingFolder = await (db.select(db.folders)
        ..where((t) => t.id.equals(SystemIds.defaultFolderId))
        ..limit(1))
      .getSingleOrNull();
  if (existingFolder == null) {
    // 既存フォルダの最後尾に置く
    final folders = await db.select(db.folders).get();
    final order = folders.isEmpty
        ? 0
        : folders.map((f) => f.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
    await db
        .into(db.folders)
        .insert(
          FoldersCompanion.insert(
            id: SystemIds.defaultFolderId,
            name: '保存スポット',
            orderIndex: order,
            createdAt: now,
            updatedAt: now,
            iconName: const Value('bookmark_rounded'),
            colorValue: const Value(0xFF3F51B5),
          ),
        );
  }

  // 2. 「行きたい」リスト
  final existingList = await (db.select(db.lists)
        ..where((t) => t.id.equals(SystemIds.wantListId))
        ..limit(1))
      .getSingleOrNull();
  final isFirstTime = existingList == null;
  if (isFirstTime) {
    await db
        .into(db.lists)
        .insert(
          ListsCompanion.insert(
            id: SystemIds.wantListId,
            folderId: SystemIds.defaultFolderId,
            name: '行きたい',
            orderIndex: 0,
            createdAt: now,
            updatedAt: now,
            iconName: const Value('flag_rounded'),
            colorValue: const Value(0xFFE91E63),
          ),
        );
  }

  // 3. wantToVisit からのバックフィル (初回のみ)
  if (isFirstTime) {
    await _backfillWantListFromFlag(db, now);
  }
}

Future<void> _backfillWantListFromFlag(AppDatabase db, int now) async {
  final visitedSpotIds = (await (db.select(db.visits)
            ..where((t) => t.deletedAt.isNull()))
          .get())
      .map((v) => v.spotId)
      .toSet();
  final wantSpots = await (db.select(db.spots)
        ..where((t) => t.wantToVisit.equals(true) & t.deletedAt.isNull()))
      .get();

  final pairs = <SpotListsCompanion>[];
  var order = 0;
  for (final s in wantSpots) {
    if (visitedSpotIds.contains(s.id)) continue;
    pairs.add(
      SpotListsCompanion.insert(
        id: 'spotlist-system-want-${s.id}',
        spotId: s.id,
        listId: SystemIds.wantListId,
        orderIndex: order++,
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
  if (pairs.isEmpty) return;
  await db.batch((batch) {
    batch.insertAll(db.spotLists, pairs, mode: InsertMode.insertOrIgnore);
  });
}
