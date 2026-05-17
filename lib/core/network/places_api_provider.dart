import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/network/env.dart';
import 'package:polaris/core/network/places_api_client.dart';

/// API キーが設定されていれば PlacesApiClient を返す。
/// 設定されていなければ null (UI 側で「キー未設定」を表示)。
final placesApiClientProvider = Provider<PlacesApiClient?>((ref) {
  if (!AppEnv.hasPlacesApiKey) return null;
  return PlacesApiClient(apiKey: AppEnv.placesApiKey);
});
