import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/db/app_database.dart';

/// `main()` で実際のインスタンスを `overrideWithValue` で注入する。
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider must be overridden in ProviderScope (see main.dart)',
  );
});
