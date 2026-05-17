import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder.freezed.dart';

@freezed
abstract class Folder with _$Folder {
  const factory Folder({
    required String id,
    required String name,
    required int orderIndex,
    required DateTime updatedAt,
    String? iconName,
    int? colorValue,
    String? coverPhotoUrl,
  }) = _Folder;
}
