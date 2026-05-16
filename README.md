# polaris-app

マップと連動したおでかけ用のスマホアプリ。

## Documentation

- [PRD](./docs/PRD.md) — プロダクト要件
- [TECH_STACK](./docs/TECH_STACK.md) — 技術選定
- [DATA_MODEL](./docs/DATA_MODEL.md) — データモデル
- [CLAUDE.md](./CLAUDE.md) — AI 実装規約

## Tech Stack

- **Framework**: Flutter 3.41.9 / Dart 3.11.5 (iOS 16+ / Android 10+)
- **State**: Riverpod 3.x (plain provider と `@riverpod` codegen を併用)
- **Routing**: go_router 17.x (`StatefulShellRoute.indexedStack`)
- **Local DB (予定)**: Drift (SQLite) — モック期は in-memory
- **Maps (予定)**: google_maps_flutter — モック期は擬似マップで代替
- **Network (予定)**: dio + Google Places API (New)
- **i18n**: flutter_localizations + intl (`ja` のみ、`lib/l10n/app_ja.arb`)
- **Lint**: very_good_analysis (一部ルール緩和、`analysis_options.yaml` 参照)

詳細は [docs/TECH_STACK.md](./docs/TECH_STACK.md) を参照。

## Getting Started

```bash
flutter pub get                                              # 依存解決 + l10n 生成
dart run build_runner build --delete-conflicting-outputs     # Freezed 等の codegen
flutter run                                                  # iOS シミュレータ / Android エミュレータ
```

## Status

**Phase 1 (MVP) モック実装中**。

- ✅ 主要画面 (マップ / フォルダ / リスト詳細 / スポット詳細 / 検索 / 訪問履歴 / 設定) のモック実装
- ✅ Riverpod による状態管理 (`wantToVisit` トグル・カテゴリ/訪問状態フィルタ)
- 🚧 Drift ローカル DB 永続化
- 🚧 Google Places API 接続 (検索画面の本番化)
- 🚧 google_maps_flutter 接続 (擬似マップの置換)
- 🚧 フォルダ / リスト / 訪問の作成・編集 UI

共有・認証・クラウド同期は Phase 2 で追加予定。
