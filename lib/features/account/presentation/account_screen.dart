import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polaris/features/folders/presentation/folders_provider.dart';
import 'package:polaris/features/lists/presentation/lists_provider.dart';
import 'package:polaris/features/spots/models/spot.dart';
import 'package:polaris/features/spots/models/spot_category_x.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';
import 'package:polaris/features/visits/presentation/visits_provider.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';
import 'package:polaris/shared/widgets/photo_collage.dart' show PhotoCollage;

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spots = ref.watch(allSpotsProvider);
    final folders = ref.watch(foldersProvider);
    final lists = ref.watch(listsProvider);
    final visits = ref.watch(allVisitsProvider);
    final visitedSpotIds = visits.map((v) => v.spotId).toSet();
    final gridSpots = [
      ...spots.where((s) => visitedSpotIds.contains(s.id)),
      ...spots.where((s) => !visitedSpotIds.contains(s.id) && s.wantToVisit),
      ...spots.where((s) => !visitedSpotIds.contains(s.id) && !s.wantToVisit),
    ].where((s) => s.photoUrls.isNotEmpty).toList();

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
                visitsCount: visits.length,
                foldersCount: folders.length,
                listsCount: lists.length,
                l: l,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(scheme: scheme),
            ),
            if (gridSpots.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _Empty(message: l.accountActivityEmpty),
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
    required this.visitsCount,
    required this.foldersCount,
    required this.listsCount,
    required this.l,
  });
  final int visitsCount;
  final int foldersCount;
  final int listsCount;
  final AppLocalizations l;

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
              CircleAvatar(
                radius: 38,
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  Icons.person_rounded,
                  size: 40,
                  color: scheme.onPrimaryContainer,
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
                    _StatCounter(value: listsCount, label: l.accountStatsLists),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l.accountGuestName,
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
                  onPressed: () {},
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
  _TabBarDelegate({required this.scheme});
  final ColorScheme scheme;

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
      child: const Row(
        children: [
          Expanded(
            child: _ActiveTabIndicator(
              icon: Icons.grid_on_rounded,
              isActive: true,
            ),
          ),
          Expanded(
            child: _ActiveTabIndicator(
              icon: Icons.favorite_border_rounded,
              isActive: false,
            ),
          ),
          Expanded(
            child: _ActiveTabIndicator(
              icon: Icons.bookmark_border_rounded,
              isActive: false,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _ActiveTabIndicator extends StatelessWidget {
  const _ActiveTabIndicator({required this.icon, required this.isActive});
  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? scheme.onSurface : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 20,
          color: isActive ? scheme.onSurface : scheme.onSurfaceVariant,
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
