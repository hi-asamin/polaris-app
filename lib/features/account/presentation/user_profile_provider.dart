import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/db/database_provider.dart';
import 'package:polaris/features/account/data/user_profile_repository.dart';
import 'package:polaris/features/account/models/user_profile.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(ref.watch(databaseProvider));
});

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() {
    return ref.watch(userProfileRepositoryProvider).get();
  }

  Future<void> save(UserProfile profile) async {
    final repo = ref.read(userProfileRepositoryProvider);
    await repo.upsert(profile);
    state = AsyncData(await repo.get());
  }

  Future<void> clear() async {
    final repo = ref.read(userProfileRepositoryProvider);
    await repo.clear();
    state = const AsyncData(null);
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
      UserProfileNotifier.new,
    );

/// オンボーディング完了済みか?ロード中はとりあえず true 扱いで起動ブロックを
/// 避ける (loading 時に redirect を発火させないため)。
final isOnboardedProvider = Provider<bool>((ref) {
  final state = ref.watch(userProfileProvider);
  return state.maybeWhen(data: (p) => p != null, orElse: () => true);
});
