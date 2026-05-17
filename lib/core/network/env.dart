/// アプリ起動時の `--dart-define` で渡される環境変数を一元管理。
class AppEnv {
  AppEnv._();

  static const placesApiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');

  static bool get hasPlacesApiKey => placesApiKey.isNotEmpty;
}
