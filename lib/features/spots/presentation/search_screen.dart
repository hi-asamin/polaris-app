import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/network/places_api_client.dart';
import 'package:polaris/core/network/places_api_provider.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  static const _recent = ['スターバックス', '渋谷', '京都駅', 'ラーメン'];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final client = ref.watch(placesApiClientProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l.searchHint,
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
      body: client == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Places API キーが未設定です。\n--dart-define=GOOGLE_PLACES_API_KEY=... で起動してください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : _query.isEmpty
          ? _RecentList(
              recent: _recent,
              onTap: (q) {
                _controller.text = q;
                setState(() => _query = q);
              },
              l: l,
            )
          : _SearchResults(query: _query, l: l),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query, required this.l});
  final String query;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final asyncResults = ref.watch(searchPlacesProvider(query));

    return asyncResults.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Text(
              l.searchEmpty,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) =>
              _SearchResultCard(result: results[i], l: l),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '検索エラー: $e',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.error),
          ),
        ),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({
    required this.recent,
    required this.onTap,
    required this.l,
  });
  final List<String> recent;
  final ValueChanged<String> onTap;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          l.searchRecent,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        for (final r in recent)
          ListTile(
            leading: Icon(Icons.history, color: scheme.onSurfaceVariant),
            title: Text(r),
            onTap: () => onTap(r),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          ),
      ],
    );
  }
}

class _SearchResultCard extends ConsumerStatefulWidget {
  const _SearchResultCard({required this.result, required this.l});
  final PlaceSearchResult result;
  final AppLocalizations l;

  @override
  ConsumerState<_SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends ConsumerState<_SearchResultCard> {
  bool _busy = false;

  /// 検索候補をタップした時の挙動: **保存はしない**。
  /// 場所の詳細をプレビューするボトムシートを開くだけ。
  /// 保存はシート内 (またはカード右の「保存」ボタン) の明示的操作で行う。
  Future<void> _openPreview() async {
    if (_busy) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PlacePreviewSheet(
        result: widget.result,
        l: widget.l,
        onSave: _saveAndPickFolder,
      ),
    );
  }

  /// 「保存」ボタンの挙動: 保存 → SaveToListSheet (フォルダ選択) を開く。
  /// プレビューシート内の保存ボタンからも呼ばれる。
  Future<void> _saveAndPickFolder() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final spotId = await ref
          .read(spotsNotifierProvider.notifier)
          .saveFromPlace(widget.result);
      if (!mounted) return;
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _SaveToListSheetForSearch(spotId: spotId),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('スポットを保存しました')),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final r = widget.result;
    final client = ref.read(placesApiClientProvider);
    final photoUrl = (r.photoNames.isNotEmpty && client != null)
        ? client.photoUrl(r.photoNames.first, maxWidthPx: 300)
        : null;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _busy ? null : _openPreview,
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 76,
                child: photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (c, _) =>
                            Container(color: scheme.surfaceContainerHighest),
                        errorWidget: (c, _, _) =>
                            Container(color: scheme.surfaceContainerHighest),
                      )
                    : Container(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.place_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (r.formattedAddress != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      r.formattedAddress!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (r.rating != null) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          r.rating!.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall,
                        ),
                        if (r.ratingCount != null) ...[
                          const SizedBox(width: 2),
                          Text(
                            '(${r.ratingCount})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                      const Spacer(),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                        icon: _busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.bookmark_add_outlined,
                                size: 16,
                              ),
                        label: Text(widget.l.searchSaveToList),
                        onPressed: _busy ? null : _saveAndPickFolder,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// 検索候補タップで開くプレビューシート。保存は一切しない。
/// 「保存」ボタンを押した時だけ親 (_SearchResultCard) に保存処理を委譲する。
class _PlacePreviewSheet extends StatelessWidget {
  const _PlacePreviewSheet({
    required this.result,
    required this.l,
    required this.onSave,
  });

  final PlaceSearchResult result;
  final AppLocalizations l;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mediaSize = MediaQuery.sizeOf(context);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaSize.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.photoNames.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _PreviewPhoto(name: result.photoNames.first),
                    ),
                  ),
                ),
              Text(
                result.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              if (result.formattedAddress != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        result.formattedAddress!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (result.rating != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Color(0xFFFFC107),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      result.rating!.toStringAsFixed(1),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (result.ratingCount != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${result.ratingCount} 件のレビュー)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await onSave();
                  },
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(l.searchSaveToList),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewPhoto extends ConsumerWidget {
  const _PreviewPhoto({required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(placesApiClientProvider);
    final scheme = Theme.of(context).colorScheme;
    if (client == null) {
      return Container(color: scheme.surfaceContainerHighest);
    }
    return CachedNetworkImage(
      imageUrl: client.photoUrl(name, maxWidthPx: 1200),
      fit: BoxFit.cover,
      placeholder: (c, _) => Container(color: scheme.surfaceContainerHighest),
      errorWidget: (c, _, _) =>
          Container(color: scheme.surfaceContainerHighest),
    );
  }
}

/// 検索後の「リストに保存」シート。spot_detail の同名コンポーネントと
/// ほぼ同じ実装だが、ファイル間循環依存を避けてここに小さく置く。
class _SaveToListSheetForSearch extends ConsumerStatefulWidget {
  const _SaveToListSheetForSearch({required this.spotId});
  final String spotId;

  @override
  ConsumerState<_SaveToListSheetForSearch> createState() =>
      _SaveToListSheetForSearchState();
}

class _SaveToListSheetForSearchState
    extends ConsumerState<_SaveToListSheetForSearch> {
  late Set<String> _selected;
  bool _initialized = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final folders = ref.watch(foldersProvider);
    final allLists = ref.watch(listsProvider);
    final pairs = ref.watch(spotListPairsProvider);

    if (!_initialized) {
      _selected = pairs
          .where((p) => p.spotId == widget.spotId)
          .map((p) => p.listId)
          .toSet();
      _initialized = true;
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'リストに保存',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final folder in folders) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_rounded,
                              size: 16,
                              color: folder.colorValue != null
                                  ? Color(folder.colorValue!)
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              folder.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final list in allLists.where(
                        (l) => l.folderId == folder.id,
                      ))
                        CheckboxListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _selected.contains(list.id),
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selected.add(list.id);
                            } else {
                              _selected.remove(list.id);
                            }
                          }),
                          title: Text(list.name),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('スキップ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final pairs = ref.read(spotListPairsProvider);
    final current = pairs
        .where((p) => p.spotId == widget.spotId)
        .map((p) => p.listId)
        .toSet();
    final toAdd = _selected.difference(current);
    final toRemove = current.difference(_selected);
    final notifier = ref.read(spotListPairsNotifierProvider.notifier);
    for (final listId in toAdd) {
      await notifier.add(widget.spotId, listId);
    }
    for (final listId in toRemove) {
      await notifier.remove(widget.spotId, listId);
    }
    if (!mounted) return;
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.pop(context);
  }
}

/// クエリごとに検索結果をキャッシュ。
/// Riverpod が autoDispose しないので、同一クエリの再入力は API を叩かない。
final searchPlacesProvider =
    FutureProvider.family<List<PlaceSearchResult>, String>((ref, query) async {
  final client = ref.watch(placesApiClientProvider);
  if (client == null) return const [];
  return client.searchText(query);
});
