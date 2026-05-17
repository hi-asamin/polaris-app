import 'package:dio/dio.dart';

/// Google Places API (New) のラッパ。
/// REST API v1: https://places.googleapis.com/v1/places/{PLACE_ID}
class PlacesApiClient {
  PlacesApiClient({required this.apiKey})
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://places.googleapis.com/v1',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  final String apiKey;
  final Dio _dio;

  /// 指定 Place ID の詳細を取得。
  /// Field mask は Place Details (Pro) と Details (Enterprise) の課金境界を
  /// 意識して必要最小限に絞っている。
  Future<PlaceDetails> details(String placeId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/places/$placeId',
      options: Options(
        headers: {
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': [
            'id',
            'displayName',
            'formattedAddress',
            'addressComponents',
            'nationalPhoneNumber',
            'internationalPhoneNumber',
            'websiteUri',
            'regularOpeningHours.weekdayDescriptions',
            'rating',
            'userRatingCount',
            'priceLevel',
            'editorialSummary',
            'photos.name',
            'types',
            'primaryType',
            'location',
            'googleMapsUri',
          ].join(','),
          'Accept-Language': 'ja',
        },
      ),
    );
    return PlaceDetails.fromJson(response.data!);
  }

  /// テキスト検索。Places API (New) `places:searchText`。
  /// 言語は ja、リージョン JP を明示。
  Future<List<PlaceSearchResult>> searchText(
    String query, {
    int maxResults = 15,
  }) async {
    if (query.trim().isEmpty) return const [];
    final response = await _dio.post<Map<String, dynamic>>(
      '/places:searchText',
      data: {
        'textQuery': query,
        'languageCode': 'ja',
        'regionCode': 'JP',
        'maxResultCount': maxResults,
      },
      options: Options(
        headers: {
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': [
            'places.id',
            'places.displayName',
            'places.formattedAddress',
            'places.location',
            'places.types',
            'places.primaryType',
            'places.rating',
            'places.userRatingCount',
            'places.photos.name',
          ].join(','),
        },
      ),
    );
    final places = (response.data?['places'] as List<dynamic>?) ?? [];
    return [
      for (final p in places)
        PlaceSearchResult.fromJson(p as Map<String, dynamic>),
    ];
  }

  /// 写真メディア URL (実際には別エンドポイント; アプリ側で組み立て)。
  String photoUrl(String photoName, {int maxWidthPx = 800}) {
    return 'https://places.googleapis.com/v1/$photoName/media'
        '?maxWidthPx=$maxWidthPx&key=$apiKey';
  }
}

class PlaceSearchResult {
  PlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    this.formattedAddress,
    this.types = const [],
    this.primaryType,
    this.rating,
    this.ratingCount,
    this.photoNames = const [],
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    return PlaceSearchResult(
      placeId: json['id'] as String,
      name:
          (json['displayName'] as Map<String, dynamic>?)?['text'] as String? ??
          '',
      lat: (location?['latitude'] as num?)?.toDouble() ?? 0,
      lng: (location?['longitude'] as num?)?.toDouble() ?? 0,
      formattedAddress: json['formattedAddress'] as String?,
      types: ((json['types'] as List<dynamic>?) ?? []).cast<String>(),
      primaryType: json['primaryType'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['userRatingCount'] as int?,
      photoNames: [
        for (final p in (json['photos'] as List<dynamic>?) ?? [])
          if ((p as Map<String, dynamic>)['name'] is String)
            p['name'] as String,
      ],
    );
  }

  final String placeId;
  final String name;
  final double lat;
  final double lng;
  final String? formattedAddress;
  final List<String> types;
  final String? primaryType;
  final double? rating;
  final int? ratingCount;
  final List<String> photoNames;
}

/// Places API レスポンスの軽量モデル (Freezed を使わず手書きで dependencies を増やさない)。
class PlaceDetails {
  PlaceDetails({
    required this.placeId,
    this.name,
    this.formattedAddress,
    this.phoneNumber,
    this.websiteUri,
    this.openingHours,
    this.rating,
    this.ratingCount,
    this.priceLevel,
    this.editorialSummary,
    this.photoNames = const [],
    this.types = const [],
    this.primaryType,
    this.lat,
    this.lng,
    this.prefecture,
    this.city,
    this.googleMapsUri,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final addressComponents = (json['addressComponents'] as List<dynamic>?) ?? [];
    String? prefecture;
    String? city;
    for (final raw in addressComponents) {
      final c = raw as Map<String, dynamic>;
      final types = (c['types'] as List<dynamic>?)?.cast<String>() ?? [];
      if (types.contains('administrative_area_level_1')) {
        prefecture = c['longText'] as String?;
      } else if (types.contains('locality')) {
        city = c['longText'] as String?;
      } else if (city == null &&
          types.contains('administrative_area_level_2')) {
        city = c['longText'] as String?;
      }
    }

    final hoursJson = json['regularOpeningHours'] as Map<String, dynamic>?;
    Map<String, String>? hours;
    if (hoursJson != null) {
      final descriptions =
          (hoursJson['weekdayDescriptions'] as List<dynamic>?)?.cast<String>();
      if (descriptions != null && descriptions.isNotEmpty) {
        hours = <String, String>{};
        // 'Monday: 9:00 AM – 6:00 PM' のような行を分解する。
        // ローカライズ済み (Accept-Language: ja) なら '月曜日: 9:00–18:00' になる。
        for (final line in descriptions) {
          final idx = line.indexOf(': ');
          if (idx > 0) {
            hours[line.substring(0, idx)] = line.substring(idx + 2);
          } else {
            hours[line] = '';
          }
        }
      }
    }

    final location = json['location'] as Map<String, dynamic>?;

    return PlaceDetails(
      placeId: json['id'] as String,
      name: (json['displayName'] as Map<String, dynamic>?)?['text'] as String?,
      formattedAddress: json['formattedAddress'] as String?,
      phoneNumber: json['nationalPhoneNumber'] as String? ??
          json['internationalPhoneNumber'] as String?,
      websiteUri: json['websiteUri'] as String?,
      openingHours: hours,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['userRatingCount'] as int?,
      priceLevel: _priceLevelToInt(json['priceLevel'] as String?),
      editorialSummary:
          (json['editorialSummary'] as Map<String, dynamic>?)?['text']
              as String?,
      photoNames: [
        for (final p in (json['photos'] as List<dynamic>?) ?? [])
          if ((p as Map<String, dynamic>)['name'] is String)
            p['name'] as String,
      ],
      types: ((json['types'] as List<dynamic>?) ?? []).cast<String>(),
      primaryType: json['primaryType'] as String?,
      lat: (location?['latitude'] as num?)?.toDouble(),
      lng: (location?['longitude'] as num?)?.toDouble(),
      prefecture: prefecture,
      city: city,
      googleMapsUri: json['googleMapsUri'] as String?,
    );
  }

  final String placeId;
  final String? name;
  final String? formattedAddress;
  final String? phoneNumber;
  final String? websiteUri;
  final Map<String, String>? openingHours;
  final double? rating;
  final int? ratingCount;
  final int? priceLevel;
  final String? editorialSummary;
  final List<String> photoNames;
  final List<String> types;
  final String? primaryType;
  final double? lat;
  final double? lng;
  final String? prefecture;
  final String? city;
  final String? googleMapsUri;
}

int? _priceLevelToInt(String? s) {
  switch (s) {
    case 'PRICE_LEVEL_FREE':
      return 0;
    case 'PRICE_LEVEL_INEXPENSIVE':
      return 1;
    case 'PRICE_LEVEL_MODERATE':
      return 2;
    case 'PRICE_LEVEL_EXPENSIVE':
      return 3;
    case 'PRICE_LEVEL_VERY_EXPENSIVE':
      return 4;
    default:
      return null;
  }
}
