import 'package:drift/drift.dart';
import 'package:polaris/core/db/app_database.dart';

/// システム所属のフォルダ固定 ID。これらは削除不可。
/// 1 階層フォルダ構造への移行後、リストの概念は廃止し、
/// 「行きたい」はトップレベルの専用フォルダ。
class SystemIds {
  SystemIds._();

  /// 「行きたい」システムフォルダ。
  /// - 未訪問スポットを保存する時にデフォルトでチェック
  /// - 訪問記録を入れると自動で外れる
  /// - ユーザーは手動で add/remove も可能
  static const String wantFolderId = 'folder-system-want';

  static const Set<String> protectedFolderIds = {wantFolderId};

  // ---- 旧定数 (互換のため一時的に残す。v5 移行後の参照は spot_folders 経由) ----
  @Deprecated('Use wantFolderId. Lists is being removed.')
  static const String defaultFolderId = 'folder-system-default';
  @Deprecated('Use wantFolderId. Lists is being removed.')
  static const String wantListId = 'list-system-want';
  @Deprecated('Lists are being phased out.')
  static const Set<String> protectedListIds = {wantListId};
}

/// アプリ起動時にシステムフォルダを初期化する。
///
/// オンボーディング完了済み (= UserProfile が存在する) ユーザーに対して呼ぶ。
/// 何度呼んでも副作用が増えない idempotent な実装。
///
/// 役目:
/// 1. 「行きたい」システムフォルダが無ければ作る
/// 2. spots.wantToVisit = true かつ未訪問のスポットを「行きたい」フォルダに
///    バックフィル (旧 wantToVisit フラグ + 旧「行きたい」リストからの移行用)
/// 3. 旧「保存スポット」フォルダが残っている場合は softDelete してリスト UI から消す
Future<void> ensureSystemListsExist(AppDatabase db) async {
  final now = DateTime.now().millisecondsSinceEpoch;

  // 1. 「行きたい」フォルダ
  final existingWantFolder = await (db.select(db.folders)
        ..where((t) => t.id.equals(SystemIds.wantFolderId))
        ..limit(1))
      .getSingleOrNull();
  final isFirstTime = existingWantFolder == null;
  if (isFirstTime) {
    // ユーザーフォルダの先頭に置きたいので orderIndex は最小値 - 1
    final folders = await db.select(db.folders).get();
    final minOrder = folders.isEmpty
        ? 0
        : folders.map((f) => f.orderIndex).reduce((a, b) => a < b ? a : b);
    await db
        .into(db.folders)
        .insert(
          FoldersCompanion.insert(
            id: SystemIds.wantFolderId,
            name: '行きたい',
            orderIndex: minOrder - 1,
            createdAt: now,
            updatedAt: now,
            iconName: const Value('flag_rounded'),
            colorValue: const Value(0xFFE91E63),
          ),
        );
  }

  // 2. wantToVisit フラグ & 旧システムリストからのバックフィル (初回のみ)
  if (isFirstTime) {
    await _backfillWantFolder(db, now);
  }

  // 3. 旧「保存スポット」フォルダの soft delete (idempotent)
  await (db.update(db.folders)
        // ignore: deprecated_member_use_from_same_package
        ..where((t) => t.id.equals(SystemIds.defaultFolderId) & t.deletedAt.isNull()))
      .write(FoldersCompanion(deletedAt: Value(now), updatedAt: Value(now)));
}

Future<void> _backfillWantFolder(AppDatabase db, int now) async {
  final visitedSpotIds = (await (db.select(db.visits)
            ..where((t) => t.deletedAt.isNull()))
          .get())
      .map((v) => v.spotId)
      .toSet();
  final wantSpots = await (db.select(db.spots)
        ..where((t) => t.wantToVisit.equals(true) & t.deletedAt.isNull()))
      .get();

  final pairs = <SpotFoldersCompanion>[];
  var order = 0;
  for (final s in wantSpots) {
    if (visitedSpotIds.contains(s.id)) continue;
    pairs.add(
      SpotFoldersCompanion.insert(
        id: 'spotfolder-system-want-${s.id}',
        spotId: s.id,
        folderId: SystemIds.wantFolderId,
        orderIndex: order++,
        addedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
  if (pairs.isEmpty) return;
  await db.batch((batch) {
    batch.insertAll(db.spotFolders, pairs, mode: InsertMode.insertOrIgnore);
  });
}
