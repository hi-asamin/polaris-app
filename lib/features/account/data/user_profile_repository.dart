import 'package:drift/drift.dart';
import 'package:polaris/core/db/app_database.dart';
import 'package:polaris/features/account/models/user_profile.dart';

/// 端末に 1 件だけ存在するプロフィールを扱う。複数アカウントは Phase 1 では
/// 対象外。
class UserProfileRepository {
  UserProfileRepository(this._db);
  final AppDatabase _db;

  static const _id = 'current';

  Future<UserProfile?> get() async {
    final row = await (_db.select(_db.userProfiles)
          ..where((t) => t.id.equals(_id))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return UserProfile(
      id: row.id,
      displayName: row.displayName,
      avatarColorValue: row.avatarColorValue,
      onboardedAt: DateTime.fromMillisecondsSinceEpoch(row.onboardedAt),
      sampleSet: row.sampleSet,
    );
  }

  Future<void> upsert(UserProfile profile) async {
    final ms = DateTime.now().millisecondsSinceEpoch;
    await _db
        .into(_db.userProfiles)
        .insertOnConflictUpdate(
          UserProfilesCompanion.insert(
            id: profile.id,
            displayName: profile.displayName,
            avatarColorValue: profile.avatarColorValue,
            onboardedAt: profile.onboardedAt.millisecondsSinceEpoch,
            createdAt: ms,
            updatedAt: ms,
            sampleSet: Value(profile.sampleSet),
          ),
        );
  }

  Future<void> clear() async {
    await _db.delete(_db.userProfiles).go();
  }
}
