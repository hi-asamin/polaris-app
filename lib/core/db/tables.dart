import 'package:drift/drift.dart';

/// すべての永続化テーブルに共通のメタデータ。
/// id (UUIDv7) / created_at / updated_at / deleted_at は手動で定義する
/// (Drift の `mixin` でまとめると build_runner が混乱するため愚直に書く)。

@DataClassName('FolderRow')
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get iconName => text().nullable()();
  IntColumn get colorValue => integer().nullable()();
  TextColumn get coverPhotoUrl => text().nullable()();
  IntColumn get orderIndex => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SpotListRow')
class Lists extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text().references(Folders, #id)();
  TextColumn get name => text()();
  TextColumn get iconName => text().nullable()();
  IntColumn get colorValue => integer().nullable()();
  TextColumn get coverPhotoUrl => text().nullable()();
  IntColumn get orderIndex => integer()();
  TextColumn get sortMode => text().withDefault(const Constant('manual'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SpotRow')
class Spots extends Table {
  TextColumn get id => text()();
  TextColumn get placeId => text()();
  TextColumn get name => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get primaryCategory =>
      text().withDefault(const Constant('other'))();
  TextColumn get placeTypesJson => text().nullable()();
  TextColumn get photoUrlsJson => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get prefecture => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get websiteUrl => text().nullable()();
  TextColumn get openingHoursJson => text().nullable()();
  RealColumn get rating => real().nullable()();
  IntColumn get ratingCount => integer().nullable()();
  IntColumn get priceLevel => integer().nullable()();
  TextColumn get userMemo => text().nullable()();
  TextColumn get editorialSummary => text().nullable()();
  TextColumn get googleMapsUri => text().nullable()();
  BoolColumn get wantToVisit => boolean().withDefault(const Constant(false))();
  IntColumn get lastPlaceSyncedAt => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {placeId},
  ];
}

@DataClassName('SpotListPairRow')
class SpotLists extends Table {
  TextColumn get id => text()();
  TextColumn get spotId => text().references(Spots, #id)();
  TextColumn get listId => text().references(Lists, #id)();
  IntColumn get orderIndex => integer()();
  IntColumn get addedAt => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ユーザープロフィール (Phase 1 では端末ローカル、1 行のみ存在)。
/// 同期は Phase 2 で導入予定。id は常に "current"。
@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  IntColumn get avatarColorValue => integer()();
  TextColumn get sampleSet => text().nullable()();
  IntColumn get onboardedAt => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('VisitRow')
class Visits extends Table {
  TextColumn get id => text()();
  TextColumn get spotId => text().references(Spots, #id)();
  IntColumn get visitedAt => integer()();
  TextColumn get memo => text().nullable()();
  IntColumn get rating => integer().nullable()();
  TextColumn get companions => text().nullable()();
  IntColumn get costJpy => integer().nullable()();
  TextColumn get photoUrlsJson => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
