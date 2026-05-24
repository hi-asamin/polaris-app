import 'package:freezed_annotation/freezed_annotation.dart';

part 'spot.freezed.dart';

enum SpotCategory {
  food,
  entertainment,
  sightseeing,
  shopping,
  lodging,
  other,
}

@freezed
abstract class Spot with _$Spot {
  const factory Spot({
    required String id,
    required String placeId,
    required String name,
    required double lat,
    required double lng,
    @Default(SpotCategory.other) SpotCategory primaryCategory,
    @Default([]) List<String> photoUrls,
    String? address,
    String? prefecture,
    String? city,
    String? phoneNumber,
    String? websiteUrl,
    Map<String, String>? openingHours,
    double? rating,
    int? ratingCount,
    int? priceLevel,
    String? userMemo,
    String? editorialSummary,
    String? googleMapsUri,
    DateTime? createdAt,
    // wantToVisit は「行きたい」リスト所属で表現する方針に移行したため
    // 廃止予定。互換のためフィールドは残すが、UI からは参照しない。
    @Default(false) bool wantToVisit,
    @Default(false) bool isFavorite,
  }) = _Spot;
}
