import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:polaris/core/utils/id.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/features/spots/models/spot.dart';
import 'package:polaris/features/spots/models/spot_category_x.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';
import 'package:polaris/features/visits/models/visit.dart';
import 'package:polaris/features/visits/presentation/visits_provider.dart';
import 'package:polaris/features/visits/presentation/widgets/visit_tile.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';

class SpotDetailScreen extends ConsumerWidget {
  const SpotDetailScreen({required this.spotId, super.key});
  final String spotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spot = ref.watch(spotByIdProvider(spotId));
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final visits = ref.watch(visitsBySpotProvider(spotId));

    if (spot == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Spot not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: scheme.surface,
            foregroundColor: scheme.onSurface,
            stretch: true,
            actions: [
              IconButton(
                tooltip: l.spotDetailWantToVisit,
                onPressed: () => ref
                    .read(spotsNotifierProvider.notifier)
                    .toggleWantToVisit(spot.id),
                icon: Icon(
                  spot.wantToVisit
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: spot.wantToVisit ? scheme.error : null,
                ),
              ),
              IconButton(
                tooltip: 'リストに保存',
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => _SaveToListSheet(spotId: spot.id),
                ),
                icon: const Icon(Icons.bookmark_add_outlined),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _PhotoCarousel(spot: spot),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: spot.primaryCategory.color.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              spot.primaryCategory.icon,
                              size: 14,
                              color: spot.primaryCategory.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              spot.primaryCategory.label(l),
                              style: TextStyle(
                                color: spot.primaryCategory.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (spot.priceLevel != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '¥' * (spot.priceLevel! + 1),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (visits.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: scheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l.spotDetailVisitCount(visits.length),
                                style: TextStyle(
                                  color: scheme.onPrimaryContainer,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l.spotDetailNotVisited,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    spot.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (spot.rating != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          spot.rating!.toStringAsFixed(1),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (spot.ratingCount != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${NumberFormat.decimalPattern().format(spot.ratingCount)})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (spot.address != null)
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: l.spotDetailAddressLabel,
                      value: spot.address!,
                    ),
                  if (spot.openingHours != null)
                    _InfoRow(
                      icon: Icons.schedule_outlined,
                      label: l.spotDetailHoursLabel,
                      value: spot.openingHours!.entries
                          .map((e) => '${e.key} ${e.value}')
                          .join('\n'),
                    ),
                  if (spot.phoneNumber != null)
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: l.spotDetailPhoneLabel,
                      value: spot.phoneNumber!,
                    ),
                  if (spot.websiteUrl != null)
                    _InfoRow(
                      icon: Icons.public,
                      label: l.spotDetailWebsiteLabel,
                      value: spot.websiteUrl!,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.add_circle_outline),
                          label: Text(l.spotDetailAddVisit),
                          onPressed: () => _showAddVisitSheet(
                            context,
                            spotId: spot.id,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.map_outlined),
                        label: Text(l.spotDetailOpenInMaps),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        l.spotDetailMemoLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => _EditMemoDialog(
                          spotId: spot.id,
                          initialMemo: spot.userMemo,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        width: double.infinity,
                        child: Text(
                          spot.userMemo ?? l.spotDetailMemoEmpty,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: spot.userMemo != null
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                            fontStyle: spot.userMemo != null
                                ? null
                                : FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        l.spotDetailVisitsLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${visits.length}',
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (visits.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      l.spotDetailVisitsEmpty,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: visits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  return VisitTile(
                    visit: visits[i],
                    showSpotName: false,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoCarousel extends StatelessWidget {
  const _PhotoCarousel({required this.spot});
  final Spot spot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (spot.photoUrls.isEmpty) {
      return Container(
        color: spot.primaryCategory.color.withValues(alpha: 0.2),
        child: Center(
          child: Icon(
            spot.primaryCategory.icon,
            size: 80,
            color: spot.primaryCategory.color,
          ),
        ),
      );
    }
    return PageView.builder(
      itemCount: spot.photoUrls.length,
      itemBuilder: (context, i) {
        return CachedNetworkImage(
          imageUrl: spot.photoUrls[i],
          fit: BoxFit.cover,
          placeholder: (c, _) =>
              Container(color: scheme.surfaceContainerHighest),
          errorWidget: (c, _, __) => Container(
            color: spot.primaryCategory.color.withValues(alpha: 0.2),
            child: Icon(
              spot.primaryCategory.icon,
              size: 80,
              color: spot.primaryCategory.color,
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddVisitSheet(
  BuildContext context, {
  required String spotId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AddVisitSheet(spotId: spotId),
  );
}

class _EditMemoDialog extends ConsumerStatefulWidget {
  const _EditMemoDialog({required this.spotId, this.initialMemo});
  final String spotId;
  final String? initialMemo;

  @override
  ConsumerState<_EditMemoDialog> createState() => _EditMemoDialogState();
}

class _EditMemoDialogState extends ConsumerState<_EditMemoDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialMemo ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final value = _controller.text.trim();
    await ref
        .read(spotsNotifierProvider.notifier)
        .updateMemo(widget.spotId, value.isEmpty ? null : value);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('メモを編集'),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'このスポットに関するメモ',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class _SaveToListSheet extends ConsumerStatefulWidget {
  const _SaveToListSheet({required this.spotId});
  final String spotId;

  @override
  ConsumerState<_SaveToListSheet> createState() => _SaveToListSheetState();
}

class _SaveToListSheetState extends ConsumerState<_SaveToListSheet> {
  late Set<String> _selectedListIds;
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
      _selectedListIds = pairs
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
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _selectedListIds.contains(list.id),
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selectedListIds.add(list.id);
                            } else {
                              _selectedListIds.remove(list.id);
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
                    onPressed:
                        _saving ? null : () => Navigator.pop(context),
                    child: const Text('キャンセル'),
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

    final toAdd = _selectedListIds.difference(current);
    final toRemove = current.difference(_selectedListIds);
    final notifier = ref.read(spotListPairsNotifierProvider.notifier);
    for (final listId in toAdd) {
      await notifier.add(widget.spotId, listId);
    }
    for (final listId in toRemove) {
      await notifier.remove(widget.spotId, listId);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }
}

class _AddVisitSheet extends ConsumerStatefulWidget {
  const _AddVisitSheet({required this.spotId});
  final String spotId;

  @override
  ConsumerState<_AddVisitSheet> createState() => _AddVisitSheetState();
}

class _AddVisitSheetState extends ConsumerState<_AddVisitSheet> {
  DateTime _visitedAt = DateTime.now();
  int? _rating;
  final _memoController = TextEditingController();
  final _companionsController = TextEditingController();
  final _costController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _memoController.dispose();
    _companionsController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _visitedAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _visitedAt.hour,
        _visitedAt.minute,
      );
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final cost = int.tryParse(_costController.text.trim());
    final visit = Visit(
      id: newId(),
      spotId: widget.spotId,
      visitedAt: _visitedAt,
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
      rating: _rating,
      companions: _companionsController.text.trim().isEmpty
          ? null
          : _companionsController.text.trim(),
      costJpy: cost,
    );
    await ref.read(visitsNotifierProvider.notifier).create(visit);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final dateFmt = DateFormat('y年M月d日 (E)', 'ja');
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 20 + bottomInset,
        top: 4,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '訪問を記録',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dateFmt.format(_visitedAt),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '評価',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    iconSize: 32,
                    onPressed: () => setState(
                      () => _rating = _rating == i ? null : i,
                    ),
                    icon: Icon(
                      (_rating ?? 0) >= i
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFFFC107),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'メモ',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _companionsController,
              decoration: const InputDecoration(
                hintText: '同行者 (例: 家族・友人 2名)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '金額 (円)',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
                isDense: true,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
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
}
