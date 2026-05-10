import 'package:freezed_annotation/freezed_annotation.dart';

part 'spot_list.freezed.dart';

enum SortMode { manual, addedAt, distance, name }

@freezed
abstract class SpotList with _$SpotList {
  const factory SpotList({
    required String id,
    required String folderId,
    required String name,
    String? iconName,
    int? colorValue,
    String? coverPhotoUrl,
    required int orderIndex,
    @Default(SortMode.manual) SortMode sortMode,
  }) = _SpotList;
}
