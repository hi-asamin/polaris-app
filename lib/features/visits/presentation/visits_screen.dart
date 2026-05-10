import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';
import 'package:polaris/features/visits/presentation/visits_provider.dart';
import 'package:polaris/features/visits/presentation/widgets/visit_tile.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';

class VisitsScreen extends ConsumerWidget {
  const VisitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final groups = ref.watch(visitGroupsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.visitsTitle)),
      body: groups.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 56,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.visitsEmpty,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final group in groups) ...[
                  _GroupHeader(label: _labelFor(l, group.label)),
                  const SizedBox(height: 8),
                  for (final v in group.visits) ...[
                    Consumer(
                      builder: (context, ref, _) {
                        final spot = ref.watch(spotByIdProvider(v.spotId));
                        return VisitTile(
                          visit: v,
                          spot: spot,
                          onTap: spot != null
                              ? () => context.push('/spots/${spot.id}')
                              : null,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }

  String _labelFor(AppLocalizations l, String key) {
    switch (key) {
      case 'thisMonth':
        return l.visitsThisMonth;
      case 'recent':
        return l.visitsRecent;
      case 'earlier':
        return l.visitsEarlier;
      default:
        return key;
    }
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
