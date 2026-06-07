# AGENTS.md — polaris-app 実装規約 (AI 向け)

このファイルは AI コーディングエージェント (Codex / Codex / Cursor 等) 向けの実装規約集。
**実装前に必ず参照し、これに反する書き方をしない。**

最終更新: 2026-05-16 / 関連: [docs/PRD.md](./docs/PRD.md) / [docs/TECH_STACK.md](./docs/TECH_STACK.md) / [docs/DATA_MODEL.md](./docs/DATA_MODEL.md)

## 現在の前提
- Flutter **3.41.9** / Dart **3.11.5**
- Riverpod **3.x** (`flutter_riverpod ^3.3.1` + `riverpod_annotation ^4.0.2`)
- iOS 16+ / Android API 29+
- Phase 1 = 完全ローカル (BaaS / 認証 / クラウド同期はなし)

---

## 1. 守るべきルール (Hard Rules)

1. **状態管理は Riverpod のみ。** `setState` は描画専用 Stateful (アニメーション・フォーカス制御など) でのみ可。ビジネス状態は必ず `Notifier` / `AsyncNotifier` に置く。
2. **モデルは必ず Freezed。** 素の `class` でデータモデルを書かない (現在のバージョンは `abstract class X with _$X` の Freezed 3 構文)。
3. **文字列リテラルの直書き禁止。** ユーザに見える UI 文字列は必ず `AppLocalizations` 経由 (`l10n/app_ja.arb` に追加)。モックの **データ値** (スポット名・住所・メモなど DB 由来の値) は直書き可。
4. **features 間の直接 import 禁止。** `features/spots/` から `features/lists/` を直接参照しない。共有が必要なら `core/` か `shared/` に上げる。
5. **`domain/` 層は作らない。** ロジックは Repository (`data/`) か Notifier (`presentation/`) に置く。
6. **Drift スキーマ変更時は `migrations/` に upgrade を必ず書く。** 既存データを壊さない。
7. **BaaS (Firebase / Supabase) の SDK は追加しない。** Phase 1 は完全ローカル。
8. **API キーや秘密情報をコミットしない。** `.env` または `--dart-define` で注入。
9. **生成コード (`*.g.dart`, `*.freezed.dart`, `lib/l10n/gen/`) は手で編集しない & コミットしない。** `flutter pub get` と `dart run build_runner build --delete-conflicting-outputs` で再生成する。
10. **`print` 禁止。** ロギングは `logger` パッケージ or `debugPrint` のみ。
11. **旧 Riverpod API (`StateProvider`/`StateNotifierProvider`/`ChangeNotifierProvider`) は禁止。** plain `Provider`/`NotifierProvider` または `@riverpod` codegen のいずれかを使う (§5 参照)。

---

## 2. 推奨パターン (Soft Rules)

- 1 ファイル 1 概念。300 行を超えたら分割を検討。
- 関数の引数が 4 つを超えたら、Freezed の引数オブジェクトにまとめる。
- `Future<void>` を返す Notifier メソッドは必ず例外を投げる or `AsyncValue.error` に詰める (黙殺禁止)。
- 新しいパッケージを `pubspec.yaml` に追加する前に、既存パッケージで足りないかを確認する。
- 共通 Widget を作る前に、`shared/widgets/` に既存がないか確認する。

---

## 3. フォルダ規約

```
lib/
  app/                  # 起動・ルータ・テーマ (app.dart / router.dart / theme.dart)
  core/                 # 横断的な基盤 (db, network, location, theme, utils, mock)
  features/<feature>/
    data/               # Repository, Drift DAO, API クライアント (実装後)
    models/             # Freezed モデル
    presentation/       # Riverpod Provider/Notifier, Screen, Widget
  shared/widgets/       # features 横断の共通 UI
  l10n/                 # app_ja.arb (gen/ は生成、コミットしない)
  main.dart
test/
  features/<feature>/   # lib と対称な配置
```

現在の features:
- `folders/` — フォルダ
- `lists/` — リスト
- `spots/` — スポット (検索・詳細)
- `visits/` — 訪問履歴
- `map/` — マップ画面
- `home/` — ボトムナビ統合シェル
- `settings/` — 設定

ルール:
- 新機能を追加するときは、必ず `features/<feature>/` 配下に閉じる。
- core / shared は **既存機能を 2 つ以上が共有するようになってから** 抽出する (YAGNI)。
- ユーザー管理タグの仕様廃止により `features/tags/` は **作らない**。

---

## 4. データモデル規約

詳細は [docs/DATA_MODEL.md](./docs/DATA_MODEL.md)。Phase 1 の永続化エンティティは:

- `folders` — 最上位の整理単位
- `lists` — フォルダ配下のリスト
- `spots` — 保存スポット (Places API スナップショット + ユーザー固有データ)
- `spot_lists` — Spot ↔ List の多対多
- `visits` — スポットへの訪問履歴 (1 スポットに複数件)
- `visit_photos` — 訪問の写真 (端末ローカル)

### 4.1 共通カラム
すべてのエンティティに以下のフィールドを必ず持つ:

| カラム | 型 | 用途 |
|---|---|---|
| `id` | TEXT (UUIDv7) | 主キー、端末発番 |
| `created_at` | INTEGER (UTC ms) | 作成時刻 |
| `updated_at` | INTEGER (UTC ms) | 更新時刻、Phase 2 で同期マージに使う |
| `deleted_at` | INTEGER? (UTC ms) | ソフトデリート。NULL なら有効 |

クエリは原則 `WHERE deleted_at IS NULL` を付ける。物理削除は使わない。

### 4.2 重要な禁則事項
- **ユーザー管理のタグ (`tags` テーブル等) を追加しない**。整理はフォルダ/リストで完結する仕様。
- **訪問状態のカラムを `spots` に持たない**。`visits` テーブルからクエリで派生させる。
- **`primary_category` を直接編集する UI を作らない**。Places types からの自動マッピング結果。
- Phase 2 用の列 (`soft_attributes_json`, `owner_user_id` 等) は **絶対に追加しない**。

---

## 5. Riverpod パターン (Riverpod 3.x)

### 5.1 書き方の使い分け

| ケース | 書き方 |
|---|---|
| 非同期 (Repository / API)、Family、AsyncNotifier | **`@riverpod` codegen を使う** |
| シンプルな同期 Notifier (状態あり、引数なし or 単純な family) | **plain `NotifierProvider`** OK |
| 静的な派生値 (フィルタ後リストなど) | **plain `Provider`** OK |
| `StateProvider` / `StateNotifierProvider` / `ChangeNotifierProvider` | **禁止** (旧 API) |

codegen を強制しないのは、簡素な provider に build_runner のオーバーヘッドを払わないため。
ただし、Repository / API / 永続化が絡む provider は **必ず** `@riverpod` codegen を使う (lifecycle/auto-dispose の正確性のため)。

### 5.2 codegen 版サンプル (Repository を読む場合)

```dart
@riverpod
class SpotsNotifier extends _$SpotsNotifier {
  @override
  Future<List<Spot>> build() async {
    return ref.read(spotsRepositoryProvider).list();
  }

  Future<void> add(Spot spot) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(spotsRepositoryProvider).insert(spot);
      return ref.read(spotsRepositoryProvider).list();
    });
  }
}
```

### 5.3 plain 版サンプル (モック・派生値)

```dart
// 派生 (読み取り専用)
final visibleSpotsProvider = Provider<List<Spot>>((ref) {
  final all = ref.watch(spotsNotifierProvider);
  final filter = ref.watch(spotFilterProvider);
  return all.where((s) => filter.matches(s)).toList();
});

// 同期状態
class SpotFilterNotifier extends Notifier<SpotFilter> {
  @override
  SpotFilter build() => const SpotFilter();
  void toggleCategory(SpotCategory c) { /* ... */ }
}
final spotFilterProvider =
    NotifierProvider<SpotFilterNotifier, SpotFilter>(SpotFilterNotifier.new);
```

### 5.4 共通ルール

- Family は必要なときだけ。引数なしで済むなら使わない。
- `Future<void>` を返す Notifier メソッドは例外を投げる or `AsyncValue.guard` を使う (黙殺禁止)。

---

## 6. Drift パターン

```dart
@DriftDatabase(tables: [Folders, Lists, Spots, SpotLists, Visits, VisitPhotos])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // schemaVersion を上げるたびにここに追記
    },
  );
}
```

- 多対多 (Spot↔List) は中間テーブル `spot_lists` で表現。
- 複雑なクエリは Drift DSL で書きにくいなら `customSelect` で生 SQL を使う。
- 訪問状態 (未訪問/訪問済み/訪問回数) は `visits` テーブルからの派生クエリで導出する。

---

## 7. テスト規約

- **ユニット**: `test/features/<feature>/` に配置。Repository と Notifier を中心にカバー。
- **モック**: `mocktail` を使用。`mockito` 禁止。
- **Drift**: テストでは `NativeDatabase.memory()` を使う。
- **統合テスト**: 主要フロー (保存 → 絞り込み → 訪問済み化) を 1 本書く。

```dart
// 例
class MockSpotsRepository extends Mock implements SpotsRepository {}

void main() {
  late MockSpotsRepository repo;
  setUp(() => repo = MockSpotsRepository());

  test('add inserts and reloads', () async {
    when(() => repo.insert(any())).thenAnswer((_) async {});
    when(() => repo.list()).thenAnswer((_) async => [stubSpot]);
    // ...
  });
}
```

---

## 8. コミット規約

`<type>: <要約>` 形式で日本語可。type は以下。

- `feat`: 新機能
- `fix`: バグ修正
- `refactor`: 振る舞いを変えない改善
- `docs`: ドキュメント
- `chore`: ビルド・依存関係などの雑務
- `test`: テスト追加・修正

複数の論理変更を 1 コミットに混ぜない。

---

## 9. やりがちなアンチパターン (NG 集)

| NG | 代わりに |
|---|---|
| `StatefulWidget` でビジネス状態を持つ | Riverpod の `Notifier` |
| Repository を抽象クラス化 (`abstract class`) | 具象クラスで開始。差し替え必要が出てから抽出 |
| `domain/` フォルダを作る | ロジックは Repository か Notifier に |
| `features/tags/` を作る | ユーザータグは仕様外。フォルダ・リストで整理 |
| UI 文字列の直書き `Text('保存')` | `Text(l.commonSave)` (l = `AppLocalizations.of(context)`) |
| `StateProvider` / `StateNotifierProvider` を使う | plain `NotifierProvider` か `@riverpod` codegen |
| `try-catch` で例外を黙殺 | `AsyncValue.guard` か再 throw |
| `print('debug')` | `debugPrint` または `logger` |
| `dynamic` 型の濫用 | `Object?` + 型ガード、または専用型 |
| 巨大な build メソッド (200 行超) | 子 Widget に分割 |
| 生成ファイル (`*.freezed.dart`, `*.g.dart`, `lib/l10n/gen/`) をコミット | gitignore 済み。`flutter pub get` + `build_runner` で再生成 |

---

## 10. 確認すべき事項一覧 (実装中に出会ったら止めて聞く)

- 新規パッケージ追加 (BaaS 系は厳禁、それ以外もまず相談)
- データモデルの大幅変更 (テーブル追加・主要カラム変更)
- 仕様の曖昧さ (PRD に書かれていない振る舞い)
- パフォーマンスのトレードオフ (索引追加、クエリ書き換え)
- iOS / Android プラットフォーム固有設定の追加
