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
    @Default(false) bool wantToVisit,
  }) = _Spot;
}
