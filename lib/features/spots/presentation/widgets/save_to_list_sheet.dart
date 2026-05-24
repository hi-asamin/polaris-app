import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/db/system_entities.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/features/visits/presentation/visits_provider.dart';

/// 任意のスポットを、フォルダ → リストの 2 階層ツリーから多選択保存する
/// 共通ボトムシート。spot_detail / search / curation 詳細から共通で利用。
class SaveToListSheet extends ConsumerStatefulWidget {
  const SaveToListSheet({required this.spotId, super.key});
  final String spotId;

  @override
  ConsumerState<SaveToListSheet> createState() => _SaveToListSheetState();
}

class _SaveToListSheetState extends ConsumerState<SaveToListSheet> {
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
      // 未訪問なら「行きたい」リストにデフォルトでチェックを入れる。
      // (既存所属リストが何も無い新規保存時のデフォルト提案)
      final isVisited = ref
          .read(allVisitsProvider)
          .any((v) => v.spotId == widget.spotId);
      if (!isVisited && _selected.isEmpty) {
        _selected.add(SystemIds.wantListId);
      }
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
            const SizedBox(height: 8),
            Text(
              '保存するリストを選択 (複数選択可)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
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
