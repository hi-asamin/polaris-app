import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/features/account/models/user_profile.dart';
import 'package:polaris/features/account/presentation/user_profile_provider.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/spots/models/spot.dart';
import 'package:polaris/features/spots/models/spot_category_x.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';
import 'package:polaris/features/visits/presentation/visits_provider.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';
import 'package:polaris/shared/widgets/photo_collage.dart' show PhotoCollage;

/// アカウントタブで表示するグリッドの 3 軸。
/// - visited: visits テーブルに記録のあるスポット (= 過去のアルバム)
/// - favorite: Spot.isFavorite == true のお気に入り
/// - saved: 何らかのリストに所属するスポット (= リスト保存全体)
enum AccountTab { visited, favorite, saved }

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  AccountTab _tab = AccountTab.visited;

  Future<void> _openEditSheet(UserProfile? current) async {
    if (current == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => _EditProfileSheet(initial: current),
    );
  }

  /// 現在のタブに応じて表示するスポット一覧を計算する。
  /// 各タブで「写真がある」しばりは共通 (グリッド体裁を保つため)。
  List<Spot> _spotsForTab({
    required List<Spot> all,
    required Set<String> visitedSpotIds,
    required Set<String> folderMemberSpotIds,
  }) {
    Iterable<Spot> base;
    switch (_tab) {
      case AccountTab.visited:
        base = all.where((s) => visitedSpotIds.contains(s.id));
      case AccountTab.favorite:
        base = all.where((s) => s.isFavorite);
      case AccountTab.saved:
        base = all.where((s) => folderMemberSpotIds.contains(s.id));
    }
    return base.where((s) => s.photoUrls.isNotEmpty).toList();
  }

  String _emptyMessage() {
    switch (_tab) {
      case AccountTab.visited:
        return 'まだ訪れた場所がありません';
      case AccountTab.favorite:
        return 'ハートを押した場所がここに集まります';
      case AccountTab.saved:
        return 'フォルダに保存された場所はまだありません';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spots = ref.watch(allSpotsProvider);
    final folders = ref.watch(foldersProvider);
    final visits = ref.watch(allVisitsProvider);
    final pairs = ref.watch(spotFolderPairsProvider);
    final profile = ref.watch(userProfileProvider).value;
    final visitedSpotIds = visits.map((v) => v.spotId).toSet();
    final folderMemberSpotIds = pairs.map((p) => p.spotId).toSet();
    final gridSpots = _spotsForTab(
      all: spots,
      visitedSpotIds: visitedSpotIds,
      folderMemberSpotIds: folderMemberSpotIds,
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: false,
              floating: false,
              titleSpacing: 16,
              backgroundColor: scheme.surface,
              foregroundColor: scheme.onSurface,
              title: Text(
                l.accountTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: l.settingsTitle,
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.settings_outlined),
                ),
                const SizedBox(width: 4),
              ],
            ),
            SliverToBoxAdapter(
              child: _ProfileHeader(
                profile: profile,
                visitsCount: visits.length,
                foldersCount: folders.length,
                savedCount: folderMemberSpotIds.length,
                l: l,
                onEdit: () => _openEditSheet(profile),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                scheme: scheme,
                activeTab: _tab,
                onSelect: (t) => setState(() => _tab = t),
              ),
            ),
            if (gridSpots.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _Empty(message: _emptyMessage()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _GridSpotTile(spot: gridSpots[i]),
                    childCount: gridSpots.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.visitsCount,
    required this.foldersCount,
    required this.savedCount,
    required this.l,
    required this.onEdit,
  });
  final UserProfile? profile;
  final int visitsCount;
  final int foldersCount;
  final int savedCount;
  final AppLocalizations l;
  final VoidCallback onEdit;

  String get _initial {
    final name = profile?.displayName.trim() ?? '';
    if (name.isEmpty) return '?';
    return name.characters.first.toUpperCase();
  }

  Color get _avatarColor {
    final v = profile?.avatarColorValue;
    return v == null ? const Color(0xFF3F51B5) : Color(v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: _avatarColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _avatarColor.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  _initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCounter(
                      value: visitsCount,
                      label: l.accountStatsVisits,
                    ),
                    _StatCounter(
                      value: foldersCount,
                      label: l.accountStatsFolders,
                    ),
                    _StatCounter(value: savedCount, label: '保存'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile?.displayName ?? l.accountGuestName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l.accountTagline,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onEdit,
                  child: Text(l.accountEditProfile),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(l.accountShare),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCounter extends StatelessWidget {
  const _StatCounter({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate({
    required this.scheme,
    required this.activeTab,
    required this.onSelect,
  });
  final ColorScheme scheme;
  final AccountTab activeTab;
  final ValueChanged<AccountTab> onSelect;

  static const double _height = 46;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActiveTabIndicator(
              icon: Icons.grid_on_rounded,
              isActive: activeTab == AccountTab.visited,
              tooltip: '訪問済み',
              onTap: () => onSelect(AccountTab.visited),
            ),
          ),
          Expanded(
            child: _ActiveTabIndicator(
              icon: Icons.favorite_border_rounded,
              isActive: activeTab == AccountTab.favorite,
              tooltip: 'お気に入り',
              onTap: () => onSelect(AccountTab.favorite),
            ),
          ),
          Expanded(
            child: _ActiveTabIndicator(
              icon: Icons.bookmark_border_rounded,
              isActive: activeTab == AccountTab.saved,
              tooltip: 'リスト保存',
              onTap: () => onSelect(AccountTab.saved),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.activeTab != activeTab;
}

class _ActiveTabIndicator extends StatelessWidget {
  const _ActiveTabIndicator({
    required this.icon,
    required this.isActive,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final bool isActive;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? scheme.onSurface : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Tooltip(
          message: tooltip,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isActive ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _GridSpotTile extends StatelessWidget {
  const _GridSpotTile({required this.spot});
  final Spot spot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/spots/${spot.id}'),
      child: PhotoCollage(
        photos: spot.photoUrls.take(1).toList(),
        fallbackColor: spot.primaryCategory.color.withValues(alpha: 0.18),
        fallbackIcon: spot.primaryCategory.icon,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.grid_view_rounded,
            size: 48,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// アカウント画面から呼び出すプロフィール編集シート (名前 + 色)。
/// サンプルセットの再投入はここでは行わない。
class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.initial});
  final UserProfile initial;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _name;
  late int _colorValue;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial.displayName);
    _colorValue = widget.initial.avatarColorValue;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _initial {
    final t = _name.text.trim();
    if (t.isEmpty) return '?';
    return t.characters.first.toUpperCase();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名前を入力してください')),
      );
      return;
    }
    setState(() => _saving = true);
    final updated = widget.initial.copyWith(
      displayName: _name.text.trim(),
      avatarColorValue: _colorValue,
    );
    await ref.read(userProfileProvider.notifier).save(updated);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: ListenableBuilder(
          listenable: _name,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'プロフィールを編集',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color(_colorValue),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              Color(_colorValue).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    for (final c in AvatarColor.values)
                      GestureDetector(
                        onTap: () => setState(() => _colorValue = c.argb),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(c.argb),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _colorValue == c.argb
                                  ? scheme.onSurface
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _name,
                  maxLength: 24,
                  decoration: const InputDecoration(
                    labelText: '表示名',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        child: const Text('キャンセル'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('保存'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
