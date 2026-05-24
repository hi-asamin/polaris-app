import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/core/db/database_provider.dart';
import 'package:polaris/core/samples/sample_data.dart';
import 'package:polaris/features/account/models/user_profile.dart';
import 'package:polaris/features/account/presentation/user_profile_provider.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';
import 'package:polaris/features/visits/presentation/visits_provider.dart';

/// 初回起動時のオンボーディングフロー。
///
/// 3 ステップ:
/// 1. Welcome (タグライン + 始める)
/// 2. Profile (名前 + アバター色)
/// 3. Sample (東京 / 京都 / 入れない)
///
/// 完了時に [UserProfile] を保存し、選ばれたサンプルを投入してから /map へ遷移。
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  AvatarColor _avatarColor = AvatarColor.indigo;
  SampleSet _sampleSet = SampleSet.tokyo;
  bool _submitting = false;

  static const int _pageCount = 3;
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    // 各ページの簡易バリデーション。
    if (_page == 1 && _nameController.text.trim().isEmpty) {
      await HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名前を入力してください')),
      );
      return;
    }
    if (_page < _pageCount - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _finish();
  }

  Future<void> _back() async {
    if (_page == 0) return;
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      // 1. プロフィール保存
      final profile = UserProfile(
        id: 'current',
        displayName: _nameController.text.trim(),
        avatarColorValue: _avatarColor.argb,
        onboardedAt: DateTime.now(),
        sampleSet: _sampleSet.key,
      );
      await ref.read(userProfileProvider.notifier).save(profile);

      // 2. サンプル投入 (none ならノーオペ)
      if (_sampleSet != SampleSet.none) {
        final db = ref.read(databaseProvider);
        await loadSample(db, _sampleSet);
        // 関連 provider を invalidate して画面に反映させる
        ref
          ..invalidate(foldersProvider)
          ..invalidate(listsProvider)
          ..invalidate(spotsNotifierProvider)
          ..invalidate(spotListPairsNotifierProvider)
          ..invalidate(visitsNotifierProvider);
      }

      if (!mounted) return;
      context.go('/map');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 進捗ドット
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pageCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _WelcomePage(),
                  _ProfilePage(
                    nameController: _nameController,
                    selectedColor: _avatarColor,
                    onColorSelected: (c) =>
                        setState(() => _avatarColor = c),
                  ),
                  _SamplePage(
                    selected: _sampleSet,
                    onSelected: (s) => setState(() => _sampleSet = s),
                  ),
                ],
              ),
            ),
            // フッターのボタン群
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: _submitting ? null : _back,
                      child: const Text('戻る'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _submitting ? null : _next,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_page == _pageCount - 1 ? '始める' : '次へ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, scheme.tertiary],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'polaris へ\nようこそ。',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Google Maps が機能なら、\npolaris は気分。',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'あなただけのお気に入りスポットを、'
            'もっと丁寧に・もっと美しく整理しましょう。',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.nameController,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final TextEditingController nameController;
  final AvatarColor selectedColor;
  final ValueChanged<AvatarColor> onColorSelected;

  String get _initial {
    final text = nameController.text.trim();
    if (text.isEmpty) return '?';
    return text.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: nameController,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'あなたのことを\n教えてください',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'プロフィールは端末内にのみ保存されます。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              // アバター + 色選択
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Color(selectedColor.argb),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(selectedColor.argb).withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  for (final c in AvatarColor.values)
                    GestureDetector(
                      onTap: () => onColorSelected(c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c.argb),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c == selectedColor
                                ? scheme.onSurface
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.done,
                maxLength: 24,
                decoration: const InputDecoration(
                  labelText: '表示名',
                  hintText: '例: あさみ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SamplePage extends StatelessWidget {
  const _SamplePage({required this.selected, required this.onSelected});
  final SampleSet selected;
  final ValueChanged<SampleSet> onSelected;

  static const _options = <_SampleOption>[
    _SampleOption(
      set: SampleSet.tokyo,
      title: '東京のおすすめ',
      subtitle: '渋谷のカフェ・東京タワー・東京スカイツリー 等',
      imageUrl: 'https://picsum.photos/seed/tokyo-sample/600/400',
    ),
    _SampleOption(
      set: SampleSet.kyoto,
      title: '京都のおすすめ',
      subtitle: '伏見稲荷大社・金閣寺・嵐山 等',
      imageUrl: 'https://picsum.photos/seed/kyoto-sample/600/400',
    ),
    _SampleOption(
      set: SampleSet.none,
      title: '何も入れずに始める',
      subtitle: '自分でゼロから整理していきたい方へ。',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'サンプルを入れますか?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '入れたサンプルはあとから削除できます。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final opt = _options[i];
                final isSelected = opt.set == selected;
                return _SampleCard(
                  option: opt,
                  selected: isSelected,
                  onTap: () => onSelected(opt.set),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleOption {
  const _SampleOption({
    required this.set,
    required this.title,
    required this.subtitle,
    this.imageUrl,
  });
  final SampleSet set;
  final String title;
  final String subtitle;
  final String? imageUrl;
}

class _SampleCard extends StatelessWidget {
  const _SampleCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _SampleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.6)
          : scheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (option.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: option.imageUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (c, _) => Container(
                        width: 72,
                        height: 72,
                        color: scheme.surfaceContainerHighest,
                      ),
                      errorWidget: (c, _, _) => Container(
                        width: 72,
                        height: 72,
                        color: scheme.surfaceContainerHighest,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.draw_outlined,
                      size: 28,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: scheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
