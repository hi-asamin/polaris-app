# polaris-app 技術選定

> ステータス: Draft v0.1 / 最終更新: 2026-05-10
> 関連: [PRD.md](./PRD.md)

## 0. 設計方針

1. **早く動かす > 完璧な抽象化**: Phase 1 は単独ユーザー向け。共有が来る Phase 2 までは無理に汎化しない。
2. **境界だけは先に切る**: ただし「マップ SDK」「リモート同期」など将来差し替え得るものは、薄いインターフェースで分離しておく。
3. **コード生成は積極利用**: Riverpod / Drift / Freezed の codegen で型安全とボイラープレート削減を両立。
4. **Phase 1 はオフライン完結**: ネットワークは Places 検索と地図タイルのみ。データはローカル DB に閉じる。

---

## 1. プラットフォーム・言語

| 項目 | 採用 | 備考 |
|---|---|---|
| フレームワーク | Flutter (Stable 最新) | PRD 準拠 |
| 言語 | Dart 3.x | sound null safety / records / patterns 利用 |
| 最小 iOS | 16.0+ | PRD 準拠 |
| 最小 Android | API 29 (Android 10)+ | PRD 準拠 |

---

## 2. レイヤー別の選定

### 2.1 状態管理: **Riverpod 2.x** (`flutter_riverpod` + `riverpod_generator`)

**理由**
- コンパイル時に依存解決されるため、テストとリファクタが安全
- `@riverpod` アノテーションでボイラープレートが激減
- 非同期処理 (Places 検索など) の `AsyncValue` がそのまま UI に流せる

**代替案と却下理由**
- Provider: Riverpod の前身。新規採用する理由がない。
- Bloc: ストリーム指向で本プロダクトの粒度には重い。
- GetX: 静的シングルトン中心で、テスト容易性とアーキテクチャの境界が壊れやすい。

---

### 2.2 ルーティング: **go_router**

**理由**
- 宣言的ルーティング。ディープリンク (共有リスト URL など Phase 2) の扱いが標準的
- Flutter チームが事実上の標準として推している
- `ShellRoute` でマップ/リストの 2 ペイン構成が自然に書ける

**代替案と却下理由**
- auto_route: 機能は強いが codegen 重め。go_router で十分
- Beamer: コミュニティ規模が縮小傾向

---

### 2.3 ローカル DB: **Drift** (formerly Moor)

**理由**
- 本プロダクトのコアは「タグ × リスト × 訪問状態 × 距離」の **多軸 AND/OR 絞り込み**。SQL とインデックスで素直に解ける。
- 型安全な Dart コード生成 (`@DriftDatabase`)、生 SQL も書ける逃げ道あり
- マイグレーションが明示的で、Phase 2 のサーバ同期 (Postgres ベース想定) とスキーマを揃えやすい
- アクティブメンテナンス、Flutter コミュニティで実績豊富

**代替案と却下理由**
- **Isar v3**: 速度は魅力だが、v4 が長期ベータで将来性に不安。複雑な多軸クエリは結局自前で組む必要あり。
- **sqflite**: 低レベル過ぎる。SQL を書く意義はあるが、型安全とマイグレーションは結局自作になる。
- **ObjectBox**: ライセンス (商用は要購入)、ネイティブ依存追加のオーバーヘッド。
- **Hive**: シンプルな KVS としては良いが、関係的クエリには不向き。

---

### 2.4 マップ SDK: **google_maps_flutter** + 自前ラッパ

**理由**
- Google Places との統合が最も自然
- Phase 1 のリスクは抑えつつ、`MapView` ウィジェットで包んで内部 SDK を隠蔽 → 将来 Mapbox 等に差し替える余地を残す (PRD Q1 への暫定回答)
- 抽象化レイヤーは「描画と操作」のみ。UI 全体を覆う重い抽象化は作らない (YAGNI)

**ピンクラスタリング**: `google_maps_cluster_manager`
- 1,000 ピン超でもパフォーマンス維持できる定番パッケージ

---

### 2.5 Places API クライアント: **dio + 自前ラッパ + ローカルキャッシュ**

**理由**
- PRD R1 (API コスト) を制御するため、リクエストキャッシュ層を自前で持ちたい
- `dio` の Interceptor で API キー注入・リトライ・ロギング・キャッシュを一元化
- コミュニティ製 `google_maps_webservice` 等は更新が遅め

**キャッシュ戦略 (Phase 1 ドラフト)**
- Place Details: 24h TTL でローカル DB にキャッシュ (写真 URL は別途短期 TTL)
- Autocomplete: セッショントークンを使い、課金単位を最小化
- 保存済みスポットは Place ID と最低限のスナップショット (名前・座標・住所) を必ずローカルに持つ → オフラインでも表示可能

---

### 2.6 位置情報・権限・画像

| 用途 | パッケージ | 備考 |
|---|---|---|
| 現在位置 | `geolocator` | 標準、メンテ良好 |
| 権限ダイアログ | `permission_handler` | iOS/Android のランタイム権限差を吸収 |
| 画像表示 (Places 写真) | `cached_network_image` | ディスクキャッシュ込み |
| 画像取得 (訪問写真) | `image_picker` | カメラ/ギャラリー両対応 |
| 端末ローカル保存 | `path_provider` + アプリ内ディレクトリ | Phase 1 はクラウド保存しない (PRD Q3) |

---

### 2.7 モデル・シリアライズ: **freezed + json_serializable**

**理由**
- イミュータブルな値オブジェクト、`copyWith`、`when`/`map` パターンマッチが揃う
- Riverpod の State / Drift の DTO 変換でも型整合が取りやすい
- JSON 変換は Places API レスポンスでそのまま使える

---

### 2.8 コード生成: **build_runner**

統合する codegen
- `riverpod_generator`
- `drift_dev`
- `freezed` / `json_serializable`
- `go_router_builder` (使うか後述で判断、初期は不採用)

---

### 2.9 テスト

| 種別 | パッケージ | 方針 |
|---|---|---|
| ユニット | `flutter_test` | ドメイン層・Repository を中心にカバー |
| モック | `mocktail` | `mockito` より null safety と相性良 |
| ウィジェット | `flutter_test` | 主要画面のスナップショット & 操作 |
| 統合 | `integration_test` | 「保存 → 絞り込み → 訪問済み化」の主要ユーザフロー 1 本 |

カバレッジ目標 (Phase 1): ドメイン層 80% / 全体 60%

---

### 2.10 Lint & フォーマット: **very_good_analysis**

- `flutter_lints` より厳しめ。チームが小さいうちに規律を入れる方が後で楽。
- `dart format` を pre-commit で強制。

---

### 2.11 国際化: **flutter_localizations + intl**

- Phase 1 は **日本語のみ** リリース
- ただし最初から `AppLocalizations` 経由でテキスト管理 → Phase 3 以降の英語追加が低コスト
- 文字列リテラルの直書きはレビューで弾く

---

## 3. アーキテクチャ

### 3.1 フォルダ構成 (Feature-first + 軽い層分け)

```
lib/
  app/
    app.dart              # MaterialApp.router、テーマ
    router.dart           # go_router 定義
  core/
    db/                   # Drift データベース定義、マイグレーション
    network/              # Dio クライアント、Places API ラッパ
    location/             # geolocator ラッパ
    theme/                # ColorScheme, Typography
    utils/
  features/
    spots/                # スポット (検索・追加・詳細)
      data/               # Repository, Drift DAO, Places client
      domain/             # エンティティ, ユースケース
      presentation/       # Riverpod providers, screens, widgets
    lists/                # リスト管理
    tags/                 # タグ管理
    map/                  # マップ画面、絞り込みロジック
    visits/               # 訪問記録
  shared/
    widgets/              # 共通 UI (BottomSheet, Chip など)
  main.dart
```

**強い Clean Architecture はやらない。** `data/domain/presentation` は責務の目印程度。インタフェースだけのために層を増やさない。

### 3.2 命名

- ファイル: `snake_case.dart`
- クラス: `UpperCamelCase`
- Riverpod プロバイダ: `xxxProvider` (生成名)
- Drift テーブル: `Spots`, `Lists`, `Tags`, `Visits` (複数形)

### 3.3 ID 戦略 (同期準備)

- 全エンティティに **UUIDv7** + `updatedAt` (UTC, ms) を保持
- 端末ローカル発番なので Phase 2 でサーバ導入時もマージ可能
- ソフトデリート (`deletedAt`) を最初から導入 → 共有時の論理削除に備える

---

## 4. CI/CD

### Phase 1 (現状)
GitHub Actions で PR トリガに以下を並列実行:
1. `dart format --set-exit-if-changed`
2. `flutter analyze`
3. `flutter test --coverage`

### Phase 1 後半
- iOS / Android のビルドジョブ (TestFlight / Internal Testing 配布)
- Codecov などへのカバレッジアップロード

### リリース
- Fastlane を使うかは、配布開始前に判断

---

## 5. Phase 2 想定 (今は決め打ちしない)

| 項目 | 本命 | 対抗 | 備考 |
|---|---|---|---|
| BaaS / バックエンド | **Supabase** | Firebase | Postgres ベースで Drift スキーマと親和。コスト面でも有利 |
| 認証 | Apple / Google サインイン | メール認証 | Phase 2 入り口で決定 |
| 写真クラウド保存 | Supabase Storage | Cloudflare R2 | Supabase 採用なら同じプロバイダで完結 |
| Push 通知 | OneSignal | Firebase Messaging | 共有リストへの追加通知用 (Phase 2 後半) |

**Phase 1 では Supabase / Firebase の SDK は入れない。** 入れた瞬間にデータモデルが引きずられるため、純粋にローカルで作り切る。

---

## 6. 観測・運用 (Phase 1 リリース前に決定)

未決。リリースが見えてきたタイミングで以下を選定:
- クラッシュレポート: Sentry / Firebase Crashlytics
- アナリティクス: PostHog / Firebase Analytics / Amplitude
- リモコン (フィーチャーフラグ・強制アップデート): 自前 or LaunchDarkly

---

## 7. 採用パッケージ一覧 (Phase 1 想定)

```yaml
# pubspec.yaml (抜粋イメージ)
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  # 状態管理
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  # ルーティング
  go_router: ^14.0.0
  # DB
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0
  # ネットワーク
  dio: ^5.4.0
  # マップ
  google_maps_flutter: ^2.6.0
  google_maps_cluster_manager: ^3.1.0
  # 位置・権限・画像
  geolocator: ^11.0.0
  permission_handler: ^11.3.0
  cached_network_image: ^3.3.0
  image_picker: ^1.0.0
  # モデル
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  # その他
  intl: ^0.19.0
  uuid: ^4.4.0
  shared_preferences: ^2.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0
  drift_dev: ^2.18.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  mocktail: ^1.0.0
  very_good_analysis: ^6.0.0
```

> バージョンはプロジェクト初期化時に最新安定版で確定。上記は方針確認のための目安。

---

## 8. ユーザに確認したい論点

1. **ローカル DB**: Drift (SQL ベース) で進める想定だが、もし「速度最優先で Isar」希望なら再検討。
2. **Phase 2 BaaS の方向性**: 本命を Supabase と置いている。Firebase 一択にしたい (Apple サインイン即時, 既存知見) なら Phase 1 のキャッシュ層設計を変えたい。
3. **国際化**: Phase 1 は日本語のみで OK か。最初から英語も用意するなら工数が増える。
4. **アーキテクチャの厳密度**: 上記は軽量レイヤリング。「Clean Architecture をきちんと敷きたい」なら別案を出す。
5. **マップ SDK の抽象化**: 薄ラッパ案で良いか、それとも完全独立 (`MapAdapter` インタフェース化) まで踏み込むか。
