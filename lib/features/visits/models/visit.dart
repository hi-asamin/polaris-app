import 'package:freezed_annotation/freezed_annotation.dart';

part 'visit.freezed.dart';

@freezed
abstract class Visit with _$Visit {
  const factory Visit({
    required String id,
    required String spotId,
    required DateTime visitedAt,
    String? memo,
    int? rating,
    String? companions,
    int? costJpy,
    @Default([]) List<String> photoUrls,
  }) = _Visit;
}
