# polaris-app

マップと連動したおでかけ用のスマホアプリ。

## Documentation

- [PRD](./docs/PRD.md) — プロダクト要件
- [TECH_STACK](./docs/TECH_STACK.md) — 技術選定
- [DATA_MODEL](./docs/DATA_MODEL.md) — データモデル
- [CLAUDE.md](./CLAUDE.md) — AI 実装規約

## Tech Stack

- **Framework**: Flutter 3.41+ (iOS 16+ / Android 10+)
- **State**: Riverpod 3.x (codegen)
- **Routing**: go_router
- **Local DB**: Drift (SQLite)
- **Maps**: google_maps_flutter
- **Network**: dio + Google Places API (New)

## Getting Started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Status

Phase 1 (MVP) 開発中。完全ローカルで動作。共有・認証は Phase 2 で追加予定。
