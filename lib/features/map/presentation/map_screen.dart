import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
// google_maps_flutter にも Cluster / ClusterManager 型が存在するが、本ファイル
// では cluster_manager_2 側の同名型を使うため、google_maps_flutter 側は hide。
import 'package:google_maps_flutter/google_maps_flutter.dart'
    hide Cluster, ClusterManager;
import 'package:polaris/core/location/location_service.dart';
import 'package:polaris/features/spots/models/spot.dart';
import 'package:polaris/features/spots/models/spot_category_x.dart';
import 'package:polaris/features/spots/presentation/spots_provider.dart';
import 'package:polaris/l10n/gen/app_localizations.dart';

/// 初期カメラ位置 (東京駅周辺)。
const _initialCamera = CameraPosition(
  target: LatLng(35.6762, 139.6503),
  zoom: 11,
);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String? _selectedSpotId;
  GoogleMapController? _mapController;
  ClusterManager<_SpotItem>? _clusterManager;
  Set<Marker> _markers = {};
  List<_SpotItem> _items = const [];

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  ClusterManager<_SpotItem> _createClusterManager() {
    return ClusterManager<_SpotItem>(
      _items,
      _onClustersUpdated,
      markerBuilder: _buildClusterMarker,
      // zoom レベルとクラスタ閾値の段階。stopClusteringZoom 以上では
      // 個別マーカー表示に倒す。
      stopClusteringZoom: 17,
    );
  }

  void _onClustersUpdated(Set<Marker> markers) {
    if (!mounted) return;
    setState(() => _markers = markers);
  }

  void _syncItems(List<Spot> spots) {
    _items = spots.map(_SpotItem.new).toList();
    final manager = _clusterManager;
    if (manager == null) return;
    manager.setItems(_items);
  }

  Future<Marker> _buildClusterMarker(Cluster<_SpotItem> cluster) async {
    if (!cluster.isMultiple) {
      final s = cluster.items.first.spot;
      return Marker(
        markerId: MarkerId(s.id),
        position: LatLng(s.lat, s.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueFor(s.primaryCategory)),
        infoWindow: InfoWindow(
          title: s.name,
          snippet: s.address,
          onTap: () => context.push('/spots/${s.id}'),
        ),
        onTap: () => setState(() => _selectedSpotId = s.id),
      );
    }
    final icon = await _buildClusterBitmap(cluster.count);
    return Marker(
      markerId: MarkerId(cluster.getId()),
      position: cluster.location,
      icon: icon,
      onTap: () => _zoomToCluster(cluster),
    );
  }

  Future<void> _zoomToCluster(Cluster<_SpotItem> cluster) async {
    final controller = _mapController;
    if (controller == null) return;
    final currentZoom = await controller.getZoomLevel();
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        cluster.location,
        (currentZoom + 2).clamp(3.0, 20.0),
      ),
    );
  }

  Future<BitmapDescriptor> _buildClusterBitmap(int count) async {
    final scheme = Theme.of(context).colorScheme;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    const logicalSize = 56.0;
    final size = (logicalSize * ratio).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    canvas.drawCircle(
      center,
      size / 2,
      Paint()..color = scheme.primary.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      center,
      size / 2.4,
      Paint()..color = scheme.primary,
    );
    canvas.drawCircle(
      center,
      size / 2.4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2.5 * ratio),
    );

    final painter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          fontSize: 16 * ratio,
          color: scheme.onPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      )
      ..layout();
    painter.paint(
      canvas,
      Offset(
        center.dx - painter.width / 2,
        center.dy - painter.height / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      imagePixelRatio: ratio,
    );
  }

  Future<void> _centerOnSpot(Spot spot) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(spot.lat, spot.lng), 14),
    );
  }

  Future<void> _centerOnCurrentLocation() async {
    final controller = _mapController;
    if (controller == null) return;
    final pos = await ref.read(locationServiceProvider).getCurrentPosition();
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('現在地を取得できませんでした')),
        );
      }
      return;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final spots = ref.watch(filteredSpotsProvider);
    final filter = ref.watch(spotFilterProvider);
    final scheme = Theme.of(context).colorScheme;

    // filtered スポットの変化に追従して cluster manager にも反映する。
    ref.listen<List<Spot>>(filteredSpotsProvider, (_, next) {
      _syncItems(next);
    });

    // 初回フレームで cluster manager を生成 (build 中なので Theme が取れる)。
    _clusterManager ??= () {
      _items = spots.map(_SpotItem.new).toList();
      return _createClusterManager();
    }();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _initialCamera,
              onMapCreated: (c) {
                _mapController = c;
                _clusterManager!.setMapId(c.mapId);
              },
              onCameraMove: (pos) => _clusterManager!.onCameraMove(pos),
              onCameraIdle: () => _clusterManager!.updateMap(),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              // 上の検索バー・チップ分のスペースを地図のロゴ/コントロールが避けるように
              padding: const EdgeInsets.only(top: 160, bottom: 200),
              onTap: (_) => setState(() => _selectedSpotId = null),
            ),
          ),
          if (spots.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l.mapEmpty,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchBar(
                  hint: l.mapSearchHint,
                  onTap: () => context.push('/search'),
                ),
                _CategoryFilterRow(
                  selected: filter.categories,
                  onToggle: (c) =>
                      ref.read(spotFilterProvider.notifier).toggleCategory(c),
                  l: l,
                ),
                _VisitFilterRow(
                  selected: filter.visitState,
                  onSelect: (v) =>
                      ref.read(spotFilterProvider.notifier).setVisitState(v),
                  l: l,
                ),
              ],
            ),
          ),
          _BottomSpotStrip(
            spots: spots,
            selectedSpotId: _selectedSpotId,
            onSelect: (s) async {
              setState(() => _selectedSpotId = s.id);
              await _centerOnSpot(s);
            },
          ),
          Positioned(
            right: 16,
            bottom: 200,
            child: Column(
              children: [
                _MiniFab(
                  icon: Icons.my_location,
                  onPressed: _centerOnCurrentLocation,
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'map-add',
                  onPressed: () => context.push('/search'),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ClusterManager 用のラッパ。Spot 自身を mixin で汚染しないため。
class _SpotItem with ClusterItem {
  _SpotItem(this.spot);
  final Spot spot;

  @override
  LatLng get location => LatLng(spot.lat, spot.lng);
}

double _hueFor(SpotCategory c) {
  switch (c) {
    case SpotCategory.food:
      return BitmapDescriptor.hueOrange;
    case SpotCategory.entertainment:
      return BitmapDescriptor.hueViolet;
    case SpotCategory.sightseeing:
      return BitmapDescriptor.hueCyan;
    case SpotCategory.shopping:
      return BitmapDescriptor.hueRose;
    case SpotCategory.lodging:
      return BitmapDescriptor.hueAzure;
    case SpotCategory.other:
      return BitmapDescriptor.hueYellow;
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onTap});
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: scheme.surface,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.search, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                Icon(Icons.tune, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.selected,
    required this.onToggle,
    required this.l,
  });
  final Set<SpotCategory> selected;
  final ValueChanged<SpotCategory> onToggle;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          for (final c in SpotCategory.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                avatar: Icon(c.icon, size: 16, color: c.color),
                label: Text(c.label(l)),
                selected: selected.contains(c),
                onSelected: (_) => onToggle(c),
              ),
            ),
        ],
      ),
    );
  }
}

class _VisitFilterRow extends StatelessWidget {
  const _VisitFilterRow({
    required this.selected,
    required this.onSelect,
    required this.l,
  });
  final VisitFilterState selected;
  final ValueChanged<VisitFilterState> onSelect;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final items = <(VisitFilterState, String)>[
      (VisitFilterState.all, l.filterAll),
      (VisitFilterState.notVisited, l.filterNotVisited),
      (VisitFilterState.visited, l.filterVisited),
      (VisitFilterState.wantToVisit, l.filterWantToVisit),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(item.$2),
                selected: selected == item.$1,
                onSelected: (_) => onSelect(item.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniFab extends StatelessWidget {
  const _MiniFab({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: scheme.onSurface),
        ),
      ),
    );
  }
}

class _BottomSpotStrip extends StatelessWidget {
  const _BottomSpotStrip({
    required this.spots,
    required this.selectedSpotId,
    required this.onSelect,
  });

  final List<Spot> spots;
  final String? selectedSpotId;
  final ValueChanged<Spot> onSelect;

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      bottom: 16,
      child: SizedBox(
        height: 168,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: spots.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final s = spots[i];
            return _SpotMiniCard(
              spot: s,
              selected: s.id == selectedSpotId,
              onTap: () => onSelect(s),
            );
          },
        ),
      ),
    );
  }
}

class _SpotMiniCard extends StatelessWidget {
  const _SpotMiniCard({
    required this.spot,
    required this.selected,
    required this.onTap,
  });

  final Spot spot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final firstPhoto = spot.photoUrls.isNotEmpty ? spot.photoUrls.first : null;
    return GestureDetector(
      onTap: () {
        onTap();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (context.mounted) {
            context.push('/spots/${spot.id}');
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 280,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.2 : 0.1),
              blurRadius: selected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: double.infinity,
              child: firstPhoto != null
                  ? CachedNetworkImage(
                      imageUrl: firstPhoto,
                      fit: BoxFit.cover,
                      placeholder: (c, _) => Container(
                        color: scheme.surfaceContainerHighest,
                      ),
                      errorWidget: (c, _, _) => Container(
                        color: spot.primaryCategory.color.withValues(
                          alpha: 0.2,
                        ),
                        child: Icon(
                          spot.primaryCategory.icon,
                          color: spot.primaryCategory.color,
                          size: 32,
                        ),
                      ),
                    )
                  : Container(
                      color: spot.primaryCategory.color.withValues(alpha: 0.2),
                      child: Icon(
                        spot.primaryCategory.icon,
                        color: spot.primaryCategory.color,
                        size: 32,
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (spot.city != null)
                          Text(
                            spot.city!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                          ),
                      ],
                    ),
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
                        if (spot.wantToVisit)
                          Icon(
                            Icons.favorite_rounded,
                            size: 16,
                            color: scheme.error,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
