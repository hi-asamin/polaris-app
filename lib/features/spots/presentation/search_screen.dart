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
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
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
      if (mounted) setState(() => _saving = false);
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
                        icon: _saving
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
                        onPressed: _saving ? null : _save,
                      ),
                    ],
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
