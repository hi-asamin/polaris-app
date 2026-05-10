import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/features/spots/models/spot.dart';
import 'package:polaris/features/spots/models/spot_category_x.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  static const _recent = [
    'スターバックス',
    '渋谷',
    '京都駅',
    'ラーメン',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final allSpots = ref.watch(allSpotsProvider);
    final scheme = Theme.of(context).colorScheme;

    final results = _query.trim().isEmpty
        ? <Spot>[]
        : allSpots.where((s) {
            final q = _query.trim().toLowerCase();
            return s.name.toLowerCase().contains(q) ||
                (s.address?.toLowerCase().contains(q) ?? false) ||
                (s.city?.toLowerCase().contains(q) ?? false);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l.searchHint,
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
      body: _query.trim().isEmpty
          ? _RecentList(
              recent: _recent,
              onTap: (q) {
                _controller.text = q;
                setState(() => _query = q);
              },
              l: l,
            )
          : results.isEmpty
          ? Center(
              child: Text(
                l.searchEmpty,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                return _SearchResultCard(spot: results[i], l: l);
              },
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

class _SearchResultCard extends ConsumerWidget {
  const _SearchResultCard({required this.spot, required this.l});
  final Spot spot;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final firstPhoto = spot.photoUrls.isNotEmpty ? spot.photoUrls.first : null;

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
                child: firstPhoto != null
                    ? CachedNetworkImage(
                        imageUrl: firstPhoto,
                        fit: BoxFit.cover,
                        placeholder: (c, _) => Container(
                          color: scheme.surfaceContainerHighest,
                        ),
                        errorWidget: (c, _, __) => Container(
                          color: spot.primaryCategory.color.withValues(
                            alpha: 0.2,
                          ),
                          child: Icon(
                            spot.primaryCategory.icon,
                            color: spot.primaryCategory.color,
                          ),
                        ),
                      )
                    : Container(
                        color: spot.primaryCategory.color.withValues(
                          alpha: 0.2,
                        ),
                        child: Icon(
                          spot.primaryCategory.icon,
                          color: spot.primaryCategory.color,
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
                    spot.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (spot.address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      spot.address!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (spot.rating != null) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          spot.rating!.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      const Spacer(),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                        icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                        label: Text(l.searchSaveToList),
                        onPressed: () {},
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
