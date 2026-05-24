import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/app/app.dart';
import 'package:polaris/core/db/app_database.dart';
import 'package:polaris/core/db/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  // Phase 1: 起動時の自動 seed はしない。初回はオンボーディング画面で
  // ユーザーがサンプルセットを選び、選ばれたものだけが投入される。
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const PolarisApp(),
    ),
  );
}
