import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/app/app.dart';
import 'package:polaris/core/db/app_database.dart';
import 'package:polaris/core/db/database_provider.dart';
import 'package:polaris/core/db/seed.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  await seedIfEmpty(db);
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const PolarisApp(),
    ),
  );
}
