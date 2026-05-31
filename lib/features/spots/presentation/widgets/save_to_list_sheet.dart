import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/core/db/system_entities.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/visits/presentation/visits_provider.dart';

/// 任意のスポットを、フォルダの多選択チェックリストから保存する共通シート。
/// 1 階層構造への移行後、リスト概念は廃止。フォルダに直接スポットを所属させる。
/// (ファイル名は履歴を辿りやすいよう一旦 save_to_list_sheet のまま残す)。
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
    final pairs = ref.watch(spotFolderPairsProvider);

    if (!_initialized) {
      _selected = pairs
          .where((p) => p.spotId == widget.spotId)
          .map((p) => p.folderId)
          .toSet();
      // 未訪問なら「行きたい」フォルダにデフォルトでチェックを入れる。
      // (既存所属フォルダが何も無い新規保存時のデフォルト提案)
      final isVisited = ref
          .read(allVisitsProvider)
          .any((v) => v.spotId == widget.spotId);
      if (!isVisited && _selected.isEmpty) {
        _selected.add(SystemIds.wantFolderId);
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
              'フォルダに保存',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '保存するフォルダを選択 (複数選択可)',
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
                    for (final folder in folders)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _selected.contains(folder.id),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(folder.id);
                          } else {
                            _selected.remove(folder.id);
                          }
                        }),
                        secondary: Icon(
                          folder.id == SystemIds.wantFolderId
                              ? Icons.flag_rounded
                              : Icons.folder_rounded,
                          color: folder.colorValue != null
                              ? Color(folder.colorValue!)
                              : scheme.onSurfaceVariant,
                          size: 22,
                        ),
                        title: Text(
                          folder.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
    final pairs = ref.read(spotFolderPairsProvider);
    final current = pairs
        .where((p) => p.spotId == widget.spotId)
        .map((p) => p.folderId)
        .toSet();
    final toAdd = _selected.difference(current);
    final toRemove = current.difference(_selected);
    final notifier = ref.read(spotFolderPairsNotifierProvider.notifier);
    for (final folderId in toAdd) {
      await notifier.add(widget.spotId, folderId);
    }
    for (final folderId in toRemove) {
      await notifier.remove(widget.spotId, folderId);
    }
    if (!mounted) return;
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.pop(context);
  }
}
