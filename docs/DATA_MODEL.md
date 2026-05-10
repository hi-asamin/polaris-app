# polaris-app データモデル

> ステータス: Decided v1.0 / 最終更新: 2026-05-10
> 関連: [PRD.md](./PRD.md) / [TECH_STACK.md](./TECH_STACK.md) / [CLAUDE.md](../CLAUDE.md)

## 0. 設計上の確定事項 (2026-05-10)

| # | 決定 |
|---|---|
| 1 | 訪問は **1:N** (Spot に対して複数の Visit 履歴を持つ) |
| 2 | **ユーザー管理のタグは廃止**。整理は Folder → List の 2 階層 |
| 3 | カテゴリ絞り込みは **Places types からの自動マッピング** (Phase 1)。Phase 2 で LLM 推論による soft attribute 拡張 |
| 4 | 地域は **緯度経度・address_components から自動導出** (`prefecture` / `city` 列) |
| 5 | Places API データは **30 日経過で自動再取得** |

---

## 1. エンティティ関係

```
Folder (1) ─── (N) List
List   (N) ─── (M) Spot      [join: SpotList]
Spot   (1) ─── (N) Visit
Visit  (1) ─── (N) VisitPhoto
```

- **Folder**: ユーザーの最上位整理単位 (例: 「東京」「京都旅行 2026」「デート候補」)
- **List**: フォルダ内のリスト (例: 「カフェ」「ラーメン」「観光」)
- **Spot**: 保存されたスポット (1 つの Spot は複数の List に所属できる)
- **Visit**: スポットへの訪問履歴 (同じスポットに複数回行ける)
- **VisitPhoto**: 訪問時の写真 (端末ローカル保存)

「訪問状態」は **クエリで派生** させる (列としては保持しない)。詳細は §4。

---

## 2. テーブル定義

すべてのテーブルに共通: `id` (TEXT, UUIDv7), `created_at` / `updated_at` / `deleted_at` (INTEGER, UTC ms)。
クエリは原則 `WHERE deleted_at IS NULL` を付ける (ソフトデリート前提)。

### 2.1 `folders`

| カラム | 型 | 制約 | 説明 |
|---|---|---|---|
| id | TEXT | PK | UUIDv7 |
| name | TEXT | NOT NULL | フォルダ名 |
| icon_name | TEXT |  | Material アイコン名、任意 |
| color_hex | TEXT |  | アクセントカラー (`#RRGGBB`)、任意 |
| cover_photo_path | TEXT |  | 端末ローカルのカバー画像、任意 |
| order_index | INTEGER | NOT NULL | フォルダ一覧での並び順 |
| created_at | INTEGER | NOT NULL |  |
| updated_at | INTEGER | NOT NULL |  |
| deleted_at | INTEGER |  |  |

Index:
- `idx_folders_order` ON `(deleted_at, order_index)`

### 2.2 `lists`

| カラム | 型 | 制約 | 説明 |
|---|---|---|---|
| id | TEXT | PK |  |
| folder_id | TEXT | NOT NULL, FK → folders.id | 必ずフォルダに所属 |
| name | TEXT | NOT NULL |  |
| icon_name | TEXT |  |  |
| color_hex | TEXT |  |  |
| cover_photo_path | TEXT |  |  |
| order_index | INTEGER | NOT NULL | フォルダ内の並び順 |
| sort_mode | TEXT | NOT NULL DEFAULT 'manual' | `'manual' / 'added_at' / 'distance' / 'name'` |
| created_at | INTEGER | NOT NULL |  |
| updated_at | INTEGER | NOT NULL |  |
| deleted_at | INTEGER |  |  |

Index:
- `idx_lists_folder` ON `(folder_id, deleted_at, order_index)`

> フォルダ削除時は配下のリストを **カスケードソフトデリート**。Drift の `onDelete` で実装。

### 2.3 `spots`

スポット本体。Places API から取得した情報のスナップショット + ユーザー固有データ。

| カラム | 型 | 制約 | 説明 |
|---|---|---|---|
| id | TEXT | PK |  |
| place_id | TEXT | NOT NULL UNIQUE | Google Places の Place ID |
| name | TEXT | NOT NULL |  |
| address | TEXT |  | 整形された住所 |
| lat | REAL | NOT NULL |  |
| lng | REAL | NOT NULL |  |
| prefecture | TEXT |  | 自動導出 (例: "東京都") |
| city | TEXT |  | 自動導出 (例: "渋谷区") |
| phone_number | TEXT |  |  |
| website_url | TEXT |  |  |
| opening_hours_json | TEXT |  | Places の hours レスポンスを JSON で保持 |
| rating | REAL |  | Google レビューの平均 |
| user_rating_count | INTEGER |  |  |
| price_level | INTEGER |  | 0-4 |
| primary_category | TEXT | NOT NULL DEFAULT 'other' | `'food'/'entertainment'/'sightseeing'/'shopping'/'lodging'/'other'` |
| place_types_json | TEXT |  | Places types の JSON 配列 (再分類用) |
| photo_refs_json | TEXT |  | Places photo references の JSON 配列 |
| user_memo | TEXT |  | スポット単位のメモ (訪問単位ではない) |
| want_to_visit | INTEGER | NOT NULL DEFAULT 0 | 0/1 (「行きたい」フラグ) |
| last_place_synced_at | INTEGER | NOT NULL | Places API 最終取得時刻 (30 日で再取得) |
| created_at | INTEGER | NOT NULL |  |
| updated_at | INTEGER | NOT NULL |  |
| deleted_at | INTEGER |  |  |

Index:
- `idx_spots_place_id` UNIQUE ON `(place_id)`
- `idx_spots_location` ON `(lat, lng)` (距離クエリの絞り込み用)
- `idx_spots_category` ON `(primary_category, deleted_at)`
- `idx_spots_region` ON `(prefecture, city, deleted_at)`
- `idx_spots_sync` ON `(last_place_synced_at)` (再取得バッチ用)

### 2.4 `spot_lists` (Spot ↔ List 多対多)

| カラム | 型 | 制約 | 説明 |
|---|---|---|---|
| id | TEXT | PK |  |
| spot_id | TEXT | NOT NULL, FK → spots.id |  |
| list_id | TEXT | NOT NULL, FK → lists.id |  |
| order_index | INTEGER | NOT NULL | リスト内 (manual sort) の並び順 |
| added_at | INTEGER | NOT NULL | リストに追加した時刻 |
| created_at | INTEGER | NOT NULL |  |
| updated_at | INTEGER | NOT NULL |  |
| deleted_at | INTEGER |  |  |

Index:
- `idx_spot_lists_pair` UNIQUE ON `(spot_id, list_id)` WHERE `deleted_at IS NULL`
- `idx_spot_lists_list` ON `(list_id, deleted_at, order_index)`
- `idx_spot_lists_spot` ON `(spot_id, deleted_at)`

### 2.5 `visits`

1 つのスポットへの訪問記録 (1:N)。

| カラム | 型 | 制約 | 説明 |
|---|---|---|---|
| id | TEXT | PK |  |
| spot_id | TEXT | NOT NULL, FK → spots.id |  |
| visited_at | INTEGER | NOT NULL | 訪問日時 (UTC ms) |
| memo | TEXT |  | 訪問の所感 |
| rating | INTEGER |  | 1-5、任意 |
| companions | TEXT |  | 同行者メモ (例: "家族", "友人 3 名") |
| cost_jpy | INTEGER |  | かかった金額、任意 |
| created_at | INTEGER | NOT NULL |  |
| updated_at | INTEGER | NOT NULL |  |
| deleted_at | INTEGER |  |  |

Index:
- `idx_visits_spot` ON `(spot_id, visited_at DESC, deleted_at)`
- `idx_visits_date` ON `(visited_at DESC, deleted_at)` (「最近行った」スマートビュー)

### 2.6 `visit_photos`

訪問の写真 (端末ローカル保存。Phase 1 はクラウドアップロードしない)。

| カラム | 型 | 制約 | 説明 |
|---|---|---|---|
| id | TEXT | PK |  |
| visit_id | TEXT | NOT NULL, FK → visits.id |  |
| local_path | TEXT | NOT NULL | アプリ内ディレクトリ相対パス |
| caption | TEXT |  |  |
| order_index | INTEGER | NOT NULL |  |
| created_at | INTEGER | NOT NULL |  |
| deleted_at | INTEGER |  |  |

Index:
- `idx_visit_photos_visit` ON `(visit_id, deleted_at, order_index)`

---

## 3. 自動分類: `primary_category`

Places API レスポンスの `types` 配列から、保存時に 1 つのカテゴリへ集約して `spots.primary_category` に格納する。

### 3.1 マッピング表

| polaris カテゴリ | 主な Places types |
|---|---|
| `food` | restaurant, cafe, bakery, food, meal_takeaway, meal_delivery, bar |
| `entertainment` | amusement_park, movie_theater, bowling_alley, casino, night_club, spa |
| `sightseeing` | tourist_attraction, museum, art_gallery, zoo, aquarium, park, church, place_of_worship, library |
| `shopping` | shopping_mall, store, clothing_store, department_store, supermarket, book_store |
| `lodging` | lodging |
| `other` | 上記いずれにもマッチしないとき |

優先順位: `types` を先頭から走査し、最初にマッチした polaris カテゴリを採用。マッピングは `lib/core/places/category_mapper.dart` に定数として持つ → 変更が容易。

### 3.2 Phase 2 拡張 (LLM augmentation)

Places types では拾えない soft attribute (例: 「フォトジェニック」「デート向き」「子連れ OK」「静か」「個室あり」) は、Phase 2 で LLM 推論を導入し、`spots.soft_attributes_json` 列 (TEXT, 後日追加) に永続化する想定。

- 推論タイミング: スポット保存時 + 30 日再同期時
- ユーザー絞り込み UI: チップ式の追加フィルタ
- Phase 1 では **列も追加しない**。Phase 2 のスキーマ変更で対応。

---

## 4. 訪問状態の派生クエリ

DB 上に「訪問状態」列は持たない。訪問履歴 (`visits`) と「行きたい」フラグ (`spots.want_to_visit`) からクエリで導出する。

| 表示状態 | 判定 |
|---|---|
| 未訪問 | `visits` に有効レコードがない |
| 訪問済み | `visits` に有効レコードが 1 件以上ある |
| 行きたい | `spots.want_to_visit = 1` (訪問済みでも独立に立てられる: 「また行きたい」) |
| 訪問回数 | `COUNT(visits.id) WHERE deleted_at IS NULL` |
| 最終訪問日 | `MAX(visits.visited_at) WHERE deleted_at IS NULL` |

派生フィールドは Drift で `customSelect` を使ったビュー的クエリ、または Repository 層で集約する。

---

## 5. マップ絞り込みクエリ (典型例)

「東京都の食べ物カテゴリで、未訪問のスポット」:

```sql
SELECT s.* FROM spots s
LEFT JOIN visits v
  ON v.spot_id = s.id AND v.deleted_at IS NULL
WHERE s.deleted_at IS NULL
  AND s.prefecture = '東京都'
  AND s.primary_category = 'food'
GROUP BY s.id
HAVING COUNT(v.id) = 0;
```

「特定リスト内のスポット (リスト内の手動並び順で)」:

```sql
SELECT s.*, sl.order_index FROM spots s
INNER JOIN spot_lists sl
  ON sl.spot_id = s.id AND sl.deleted_at IS NULL
WHERE s.deleted_at IS NULL
  AND sl.list_id = ?
ORDER BY sl.order_index;
```

「現在地から 5 km 以内、訪問済みカフェ」:
- まず矩形 bounding box で `lat` / `lng` 索引を効かせて粗絞り
- そのあと Haversine で正確距離フィルタ (Dart 側で計算)

```sql
SELECT s.* FROM spots s
INNER JOIN visits v
  ON v.spot_id = s.id AND v.deleted_at IS NULL
WHERE s.deleted_at IS NULL
  AND s.primary_category = 'food'
  AND s.lat BETWEEN :minLat AND :maxLat
  AND s.lng BETWEEN :minLng AND :maxLng
GROUP BY s.id;
-- このあと Dart 側で 5km 内に絞る
```

---

## 6. Places データ取得・再同期

### 6.1 保存時 (新規 Spot 作成)
1. `Place Details` を取得 (Places API New)
2. `address_components` から `prefecture` / `city` を抽出
3. `types` から `primary_category` を導出
4. `last_place_synced_at = now`
5. `spots` に挿入

### 6.2 30 日再同期
- `last_place_synced_at < now - 30d` のレコードを対象
- 起動時のバックグラウンドキューで順次再取得 (1 回 N 件、低優先度)
- 詳細画面表示時にも対象なら即時再取得
- レスポンスから `name / address / opening_hours_json / rating / price_level / photo_refs_json / primary_category / prefecture / city` を更新
- `user_memo` `want_to_visit` `created_at` などユーザー固有データは触らない

### 6.3 失敗時
- ネットワークエラー: スキップして次回起動時に再試行
- Place ID が無効 (店舗閉店等): `last_place_synced_at` だけ更新し、UI で「最新情報取得不可」表示
- 永続的に取得不可なら、ユーザーが手動で削除 / 再保存できる

---

## 7. マイグレーション戦略

- 初版 `schemaVersion = 1`
- スキーマ変更ごとに `lib/core/db/migrations/` に upgrade 関数を追加
- 破壊的変更は段階移行 (新列追加 → データ移行 → 旧列削除を別バージョンに分ける)
- マイグレーションは必ずテスト (`test/core/db/migration_test.dart`) を書く

---

## 8. 想定外データ量での挙動目安

| データ規模 | 期待される挙動 |
|---|---|
| Spot 1,000 件 / Visit 5,000 件 | 全クエリ 50ms 以下、マップ描画 60fps 維持 |
| Spot 5,000 件 | フィルタクエリは索引で 100ms 以下、マップは bounding box で表示数を絞る前提 |
| Visit 50,000 件 | 「最近行った」は索引で常に高速、訪問詳細は Spot 単位ページネーション |

---

## 9. Phase 2 以降のスキーマ拡張余地 (今は実装しない)

| 用途 | 想定追加 |
|---|---|
| LLM soft attributes | `spots.soft_attributes_json` (TEXT) |
| 共有リスト | `lists.owner_user_id`, `list_members` テーブル |
| 同期 | `sync_log` テーブル (差分プッシュ用) |
| クラウド写真 | `visit_photos.remote_url` |
| プラン (順序付き訪問) | `plans` / `plan_items` |

これらは **Phase 1 では絶対に列を追加しない**。スキーマを汚さないため。
