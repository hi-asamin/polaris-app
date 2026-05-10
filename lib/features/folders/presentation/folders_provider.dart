import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/mock/mock_data.dart';
import 'package:polaris/features/folders/models/folder.dart';

final foldersProvider = Provider<List<Folder>>((ref) {
  final list = [...MockData.folders]
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return list;
});

final folderByIdProvider = Provider.family<Folder?, String>((ref, id) {
  final folders = ref.watch(foldersProvider);
  for (final f in folders) {
    if (f.id == id) return f;
  }
  return null;
});
