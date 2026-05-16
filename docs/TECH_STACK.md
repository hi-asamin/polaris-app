# polaris-app 技術選定

> ステータス: **Decided v1.1** / 最終更新: 2026-05-16
> 関連: [PRD.md](./PRD.md) / [DATA_MODEL.md](./DATA_MODEL.md) / [CLAUDE.md](../CLAUDE.md)

## 0. 設計方針

1. **早く動かす > 完璧な抽象化**: Phase 1 は単独ユーザー向け。共有が来る Phase 2 までは無理に汎化しない。
2. **AI が実装しやすいことを最優先**: 実装は AI が進めるため、層は最小、規約は明文化、codegen を厚くする。
3. **境界だけは先に切る**: マップ SDK は薄ラッパで分離。BaaS は Phase 1 では一切入れず、データモデル汚染を防ぐ。
4. **Phase 1 はオフライン完結**: ネットワークは Places 検索と地図タイルのみ。認証・クラウド同期なし。

---

## 1. プラットフォーム・言語

| 項目 | 採用 | 現在の確定値 | 備考 |
|---|---|---|---|
| フレームワーク | Flutter (Stable 最新) | **3.41.9** | PRD 準拠 |
| 言語 | Dart 3.x | **3.11.5** | sound null safety / records / patterns / `_` ワイルドカード利用 |
| 最小 iOS | 16.0+ | 16.0 (`ios/Podfile`) | PRD 準拠 |
| 最小 Android | API 29 (Android 10)+ | 29 (`android/app/build.gradle.kts`) | PRD 準拠 |
| pubspec SDK 制約 | `^3.9.2` | — | Dart は実環境で 3.11.5 |

---

## 2. レイヤー別の選定

### 2.1 状態管理: **Riverpod 3.x** (`flutter_riverpod` 3.x + `riverpod_annotation` 4.x + `riverpod_generator` 4.x)

> 当初 Riverpod 2.x を想定していたが、`drift_dev` との依存解決の都合で 3.x に統一。API はほぼ互換だが `@riverpod` codegen のサンプルは Riverpod 3 系の出力を前提とする。

**理由**
- コンパイル時に依存解決されるため、テストとリファクタが安全
- `@riverpod` アノテーションでボイラープレートが激減
- 非同期処理 (Places 検索など) の `AsyncValue` がそのまま UI に流せる

**Riverpod 3.x で取れる書き方の使い分け**
- **`@riverpod` + codegen**: Repository を読み出す Notifier、Family、AsyncNotifier など、状態や引数のある provider はこれを使う。
- **plain `Provider<T>` / `NotifierProvider`**: モックデータや読み取り専用の派生値など、状態がシンプルな provider はこれで十分。codegen のオーバーヘッドを払わない。
- **`StateProvider` / `StateNotifierProvider` / `ChangeNotifierProvider`**: 旧 API、絶対に使わない。

**代替案と却下理由**
- Provider (pkg): Riverpod の前身。新規採用する理由がない。
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

## 3. アーキテクチャ (AI 実装最適化)

### 3.1 設計方針

**Feature-first + 最小 2 層**で構成する。`domain/` 層は **作らない**。

理由:
- AI は層を増やしすぎる/層を飛ばすのどちらかをやりがち。層が少ないほど一貫性が保ちやすい。
- ユースケース的なロジックは Riverpod の `Notifier` に集約 → 「ロジックの置き場所」が一意に決まる。
- インタフェースの過剰抽象化を避ける (Repository も具象クラス。差し替え必要が出てから抽出)。
- 厚い codegen (Riverpod / Drift / Freezed) で書く量を減らし、AI のミス余地を消す。
- 規約は `CLAUDE.md` に明文化し、AI に「最頻パターンへの逃げ」をさせない。

### 3.2 フォルダ構成

```
lib/
  app/
    app.dart              # MaterialApp.router、l10n delegate、テーマ適用
    router.dart           # go_router (StatefulShellRoute.indexedStack)
    theme.dart            # ColorScheme + ThemeData
  core/
    db/                   # Drift データベース定義、マイグレーション (未実装)
    network/              # Dio クライアント、Places API ラッパ (未実装)
    location/             # geolocator ラッパ (未実装)
    theme/                # 追加トークン (現状空)
    utils/
    mock/                 # モック期のサンプルデータ (DB 接続後は削除予定)
  features/
    folders/              # フォルダ管理 (最上位の整理単位)
    lists/                # リスト管理 (フォルダ配下)
    spots/                # スポット (検索・追加・詳細)
      data/               # Repository + Drift DAO + Places client
      models/             # Freezed モデル
      presentation/       # Riverpod providers, screens, widgets
    visits/               # 訪問履歴
    map/                  # マップ画面、絞り込みロジック
    home/                 # ボトムナビ統合シェル
    settings/             # 設定画面
  shared/
    widgets/              # 共通 UI (BottomSheet, Chip など)
  l10n/
    app_ja.arb            # 日本語文字列
    gen/                  # `flutter pub get` で生成 (gitignored)
  main.dart
```

ルール:
- 1 ファイル 1 概念。300 行を超えたら分割。
- ファイル名 `snake_case.dart`、テスト同名 `_test.dart`。
- features 間の直接 import 禁止 (依存は core / shared 経由のみ)。
- ユーザー管理タグの仕様廃止に伴い `features/tags/` は **作らない**。

### 3.3 命名

- ファイル: `snake_case.dart`
- クラス: `UpperCamelCase`
- Riverpod プロバイダ: `xxxProvider` (生成名または plain `Provider` の変数名)
- Drift テーブル: `Folders`, `Lists`, `Spots`, `SpotLists`, `Visits`, `VisitPhotos` (複数形)

### 3.4 ID 戦略 (同期準備)

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

## 5. Phase 2 想定 (Phase 2 入りで選定、Phase 1 では一切依存しない)

Phase 1 は **完全ローカル**。BaaS / 認証 / クラウドストレージは Phase 2 計画時に改めて選定する。

選定候補 (確定ではない):

| 項目 | 候補 A | 候補 B | 備考 |
|---|---|---|---|
| BaaS / バックエンド | Supabase (Postgres) | Firebase (Firestore) | Drift スキーマ親和性なら A、ワンストップ性なら B |
| 認証 | Apple / Google サインイン | メール認証 | 機種変・共有のため必要 |
| 写真クラウド保存 | Supabase Storage | Cloud Storage / R2 | BaaS 選定に追従 |
| Push 通知 | OneSignal | FCM | 共有リストへの追加通知用 |

**Phase 1 不変ルール**
- BaaS の SDK は **`pubspec.yaml` に追加しない**
- データモデルが BaaS に引きずられるのを防ぐため、Phase 1 は純粋なローカルアプリとして完成させる
- 同期に備えた最小準備のみ実施 (UUIDv7 + `updatedAt` + `deletedAt` を全エンティティに保持。3.4 参照)

---

## 6. 観測・運用 (Phase 1 リリース前に決定)

未決。リリースが見えてきたタイミングで以下を選定:
- クラッシュレポート: Sentry / Firebase Crashlytics
- アナリティクス: PostHog / Firebase Analytics / Amplitude
- リモコン (フィーチャーフラグ・強制アップデート): 自前 or LaunchDarkly

---

## 7. 採用パッケージ一覧 (実際の `pubspec.yaml` 抜粋)

> 真実は `pubspec.yaml` および `pubspec.lock`。以下は 2026-05-16 時点のスナップショット。

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  # 状態管理 (Riverpod 3.x)
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^4.0.2
  # ルーティング
  go_router: ^17.2.3
  # DB
  drift: ^2.31.0
  sqlite3_flutter_libs: ^0.5.42
  path_provider: ^2.1.5
  path: ^1.9.1
  # ネットワーク
  dio: ^5.9.2
  # マップ・位置・権限
  google_maps_flutter: ^2.14.2
  geolocator: ^14.0.2
  permission_handler: ^12.0.1
  # 画像
  cached_network_image: ^3.4.1
  image_picker: ^1.2.2
  # モデル
  freezed_annotation: ^3.1.0
  json_annotation: ^4.11.0
  # その他
  intl: ^0.20.2
  uuid: ^4.5.3
  shared_preferences: ^2.5.5
  logger: ^2.7.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  build_runner: ^2.15.0
  riverpod_generator: ^4.0.3
  drift_dev: ^2.31.0
  freezed: ^3.2.5
  json_serializable: ^6.13.0
  mocktail: ^1.0.5
  very_good_analysis: ^10.2.0
```

**変更点ノート** (初版からの差分):
- Riverpod: `2.x` 想定 → **`3.x`** で確定 (`drift_dev` との依存解決の都合)。
- `google_maps_cluster_manager`: 暫定不採用。マップ画面が本物の `google_maps_flutter` に切り替わる段階で別途検討。
- `logger`: 追加。`debugPrint` で足りない場面 (例: 構造化ログ) のため。

---

## 8. 決定事項ログ

### 2026-05-10
| # | 論点 | 決定 |
|---|---|---|
| 1 | ローカル DB | **Drift** (多軸 AND/OR 絞り込みが SQL で素直、Phase 2 同期親和) |
| 2 | Phase 1 認証 | **なし**。完全ローカルで完結 |
| 3 | Phase 2 BaaS | **未決**。Phase 2 計画時に Supabase / Firebase を改めて比較 |
| 4 | 国際化 | **日本語のみ**で Phase 1 リリース。文字列管理だけは `AppLocalizations` 化 |
| 5 | アーキテクチャ | **Feature-first + 最小 2 層** (`data/` と `presentation/`)。`domain/` は作らない |
| 6 | マップ SDK 抽象化 | **L1 (薄ラッパ)**。`PolarisMapView` で `google_maps_flutter` を包む |
| 7 | AI 実装規約 | プロジェクトルートに **`CLAUDE.md`** を置き、規約を明文化 |

### 2026-05-16
| # | 論点 | 決定 |
|---|---|---|
| 8 | Flutter SDK | プロジェクト初期化時に **3.41.9** (Dart 3.11.5) で確定 |
| 9 | Riverpod バージョン | **3.x** で統一 (`flutter_riverpod ^3.3.1` + `riverpod_annotation ^4.0.2`)。`drift_dev` との依存衝突解消のため当初想定の 2.x から変更 |
| 10 | Provider 書き方 | `@riverpod` codegen と plain `Provider`/`NotifierProvider` の **併用可**。簡素な provider に codegen は強制しない。`StateProvider` 等の旧 API は禁止 |
| 11 | lint 厳格度 | 一部スタイル系ルールを `analysis_options.yaml` で無効化 (理由は同ファイルに明記)。実装フェーズで再検討 |
| 12 | マップ実装 | モック期は擬似マップ (CustomPaint) で代替。`google_maps_flutter` への切り替えは Places API 接続と同タイミング |
