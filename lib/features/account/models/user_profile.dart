import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

/// Phase 1 用のローカルプロフィール。サーバー認証は持たず、初回オンボーディング
/// で作成して端末ローカルにだけ保持する。
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String displayName,
    required int avatarColorValue,
    required DateTime onboardedAt,
    String? sampleSet,
  }) = _UserProfile;
}

/// プロフィール上のアバター候補色。
enum AvatarColor {
  rose(0xFFE91E63),
  amber(0xFFFFA000),
  teal(0xFF009688),
  indigo(0xFF3F51B5),
  violet(0xFF9C27B0),
  forest(0xFF388E3C);

  const AvatarColor(this.argb);
  final int argb;
}
