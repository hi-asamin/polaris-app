import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/core/db/system_entities.dart';
import 'package:polaris/core/utils/id.dart';
import 'package:polaris/core/utils/relative_date.dart';
import 'package:polaris/features/folders/models/folder.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/lists/models/spot_list.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';
import 'package:polaris/shared/widgets/photo_collage.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final folders = ref.watch(foldersProvider);
    final lists = ref.watch(listsProvider);

    // システム「保存スポット」フォルダ配下のリスト (= 「行きたい」等) は
    // フォルダ階層を介さず、リストタブのトップレベルにカードとして直接出す。
    // - 表示順: システムリスト → ユーザーフォルダ
    final systemLists = lists
        .where((l) => l.folderId == SystemIds.defaultFolderId)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final userFolders = folders
        .where((f) => f.id != SystemIds.defaultFolderId)
        .toList();

    final entries = <Object>[...systemLists, ...userFolders];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const _UserHeader(),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchHeaderDelegate(l: l),
            ),
            if (entries.isEmpty)
              SliverFillRemaining(child: _Empty(l: l))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final entry = entries[i];
                      if (entry is SpotList) {
                        return _SystemListCard(list: entry);
                      }
                      return _FavoriteFolderCard(folder: entry as Folder);
                    },
                    childCount: entries.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                Icons.person_rounded,
                color: scheme.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ゲスト',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'あなたのスポット',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.menu_rounded),
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SearchHeaderDelegate({required this.l});
  final AppLocalizations l;

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => context.push('/search'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: scheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '自分のスポットを検索',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: l.foldersNew,
            onPressed: () => _showCreateFolderDialog(context),
            icon: const Icon(Icons.add_rounded),
            iconSize: 26,
            color: scheme.onSurface,
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) => false;
}

class _FavoriteFolderCard extends ConsumerWidget {
  const _FavoriteFolderCard({required this.folder});
  final Folder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final photos = ref.watch(folderCoverPhotosProvider(folder.id));
    final spotCount = ref.watch(spotsCountByFolderProvider(folder.id));
    final accent = folder.colorValue != null
        ? Color(folder.colorValue!)
        : scheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/folders/${folder.id}'),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: scheme.surface,
                  child: PhotoCollage(
                    photos: photos,
                    gap: 2,
                    fallbackColor: accent.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!SystemIds.protectedFolderIds.contains(folder.id))
                  InkResponse(
                    onTap: () => _showDeleteFolderDialog(
                      context,
                      folder.id,
                      folder.name,
                    ),
                    radius: 18,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: 'スポット：$spotCount 件'),
                  const TextSpan(text: '  '),
                  TextSpan(
                    text: relativeDate(folder.updatedAt),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
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

/// システムリスト (現状は「行きたい」のみ) をフォルダ階層を介さずに
/// リストタブのトップレベルに表示するためのカード。
/// タップで /lists/:listId に直接遷移する。
class _SystemListCard extends ConsumerWidget {
  const _SystemListCard({required this.list});
  final SpotList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final spots = ref.watch(spotsByListProvider(list.id));
    final photos = spots
        .expand((s) => s.photoUrls)
        .take(4)
        .toList(growable: false);
    final accent = list.colorValue != null
        ? Color(list.colorValue!)
        : scheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/lists/${list.id}'),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: scheme.surface,
                        child: PhotoCollage(
                          photos: photos,
                          gap: 2,
                          fallbackColor: accent.withValues(alpha: 0.16),
                        ),
                      ),
                    ),
                    // システムリストであることが分かるよう左上に小さな旗バッジ
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag_rounded, size: 12, color: accent),
                            const SizedBox(width: 4),
                            Text(
                              'デフォルト',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text(
              list.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'スポット：${spots.length} 件',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l});
  final AppLocalizations l;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 40,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.folderEmpty,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l.folderEmptyHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCreateFolderDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => const _CreateFolderDialog(),
  );
}

class _CreateFolderDialog extends ConsumerStatefulWidget {
  const _CreateFolderDialog();

  @override
  ConsumerState<_CreateFolderDialog> createState() =>
      _CreateFolderDialogState();
}

class _CreateFolderDialogState extends ConsumerState<_CreateFolderDialog> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _submitting = true);
    final folders = ref.read(foldersProvider);
    final nextOrder = folders.isEmpty
        ? 0
        : folders.map((f) => f.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
    final folder = Folder(
      id: newId(),
      name: name,
      orderIndex: nextOrder,
      updatedAt: DateTime.now(),
    );
    await ref.read(foldersNotifierProvider.notifier).create(folder);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: const Text('フォルダを作成'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLength: 25,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'フォルダ名を入力'),
            onSubmitted: (_) => _submit(),
          ),
          Text(
            '25文字まで入力可能です',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(l.filterCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: const Text('作成'),
        ),
      ],
    );
  }
}

Future<void> _showDeleteFolderDialog(
  BuildContext context,
  String folderId,
  String folderName,
) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) =>
        _DeleteFolderDialog(folderId: folderId, folderName: folderName),
  );
}

class _DeleteFolderDialog extends ConsumerWidget {
  const _DeleteFolderDialog({required this.folderId, required this.folderName});
  final String folderId;
  final String folderName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: const Text('フォルダを削除'),
      content: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'フォルダ「'),
            TextSpan(
              text: folderName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: '」を削除してもよろしいですか？'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.filterCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () async {
            await ref
                .read(foldersNotifierProvider.notifier)
                .deleteFolder(folderId);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('削除'),
        ),
      ],
    );
  }
}
