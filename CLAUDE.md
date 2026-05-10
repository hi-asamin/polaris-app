# CLAUDE.md — polaris-app 実装規約 (AI 向け)

このファイルは AI コーディングエージェント (Claude / Codex / Cursor 等) 向けの実装規約集。
**実装前に必ず参照し、これに反する書き方をしない。**

関連: [docs/PRD.md](./docs/PRD.md) / [docs/TECH_STACK.md](./docs/TECH_STACK.md)

---

## 1. 守るべきルール (Hard Rules)

1. **状態管理は Riverpod のみ。** `setState` は描画専用 Stateful (アニメーション・フォーカス制御など) でのみ可。ビジネス状態は必ず `Notifier` / `AsyncNotifier` に置く。
2. **モデルは必ず Freezed。** 素の `class` でデータモデルを書かない。
3. **文字列リテラルの直書き禁止。** ユーザに見える文字列は必ず `AppLocalizations` 経由。
4. **features 間の直接 import 禁止。** `features/spots/` から `features/lists/` を直接参照しない。共有が必要なら `core/` か `shared/` に上げる。
5. **`domain/` 層は作らない。** ロジックは Repository (`data/`) か Notifier (`presentation/`) に置く。
6. **Drift スキーマ変更時は `migrations/` に upgrade を必ず書く。** 既存データを壊さない。
7. **BaaS (Firebase / Supabase) の SDK は追加しない。** Phase 1 は完全ローカル。
8. **API キーや秘密情報をコミットしない。** `.env` または `--dart-define` で注入。
9. **生成コード (`*.g.dart`, `*.freezed.dart`) は手で編集しない。** `dart run build_runner build --delete-conflicting-outputs` を使う。
10. **`print` 禁止。** ロギングは `logger` パッケージ or `debugPrint` のみ。

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
  app/                  # 起動・ルータ・テーマ
  core/                 # 横断的な基盤 (DB, network, location, theme, utils)
  features/<feature>/
    data/               # Repository, Drift DAO, API クライアント
    models/             # Freezed モデル
    presentation/       # Riverpod Notifier, Screen, Widget
  shared/widgets/       # features 横断の共通 UI
  main.dart
test/
  features/<feature>/   # lib と対称な配置
```

新機能を追加するときは、必ず `features/<feature>/` 配下に閉じる。core / shared は **既存機能を 2 つ以上が共有するようになってから** 抽出する (YAGNI)。

---

## 4. データモデル規約

すべての永続化エンティティ (Spot / List / Tag / Visit) は以下のフィールドを必ず持つ:

| カラム | 型 | 用途 |
|---|---|---|
| `id` | TEXT (UUIDv7) | 主キー、端末発番 |
| `createdAt` | INTEGER (UTC ms) | 作成時刻 |
| `updatedAt` | INTEGER (UTC ms) | 更新時刻、Phase 2 で同期マージに使う |
| `deletedAt` | INTEGER? (UTC ms) | ソフトデリート。NULL なら有効 |

クエリは原則 `WHERE deletedAt IS NULL` を付ける。物理削除は使わない。

---

## 5. Riverpod パターン

```dart
// ✅ 推奨: code generation を使う
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

- `Provider` / `StateProvider` / `StateNotifierProvider` (旧 API) は使わない。`@riverpod` のみ。
- Family は必要なときだけ。引数なしで済むなら使わない。

---

## 6. Drift パターン

```dart
@DriftDatabase(tables: [Spots, Lists, Tags, Visits, SpotTags, SpotLists])
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

- 多対多 (Spot↔Tag, Spot↔List) は中間テーブルで表現。
- 複雑なクエリは Drift DSL で書きにくいなら `customSelect` で生 SQL を使う。

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
| 文字列の直書き `Text('保存')` | `Text(loc.save)` |
| `try-catch` で例外を黙殺 | `AsyncValue.guard` か再 throw |
| `print('debug')` | `debugPrint` または `logger` |
| `dynamic` 型の濫用 | `Object?` + 型ガード、または専用型 |
| 巨大な build メソッド (200 行超) | 子 Widget に分割 |

---

## 10. 確認すべき事項一覧 (実装中に出会ったら止めて聞く)

- 新規パッケージ追加 (BaaS 系は厳禁、それ以外もまず相談)
- データモデルの大幅変更 (テーブル追加・主要カラム変更)
- 仕様の曖昧さ (PRD に書かれていない振る舞い)
- パフォーマンスのトレードオフ (索引追加、クエリ書き換え)
- iOS / Android プラットフォーム固有設定の追加
