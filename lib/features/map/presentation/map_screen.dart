import 'dart:async';

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
import 'package:polaris/features/map/presentation/widgets/spot_pin_painter.dart';
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

  // BitmapDescriptor のキャッシュ。同一キーが何度問い合わせられても 1 回しか
  // 描かない。キーは "spot:<id>:sel=<bool>" (単独ピン) と
  // "cluster:<id>:<count>:cat=<name>:sel=<bool>" (クラスタピン)。
  final Map<String, BitmapDescriptor> _bitmapCache = {};
  final Set<String> _bitmapInFlight = {};

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

  void _selectSpot(String? spotId) {
    if (_selectedSpotId == spotId) return;
    setState(() => _selectedSpotId = spotId);
    // 選択強調を反映するためマーカーを再描画。
    _clusterManager?.updateMap();
  }

  Future<Marker> _buildClusterMarker(Cluster<_SpotItem> cluster) async {
    if (!cluster.isMultiple) {
      final s = cluster.items.first.spot;
      final isSelected = s.id == _selectedSpotId;
      final icon = _resolveSpotPin(s, selected: isSelected);
      return Marker(
        markerId: MarkerId(s.id),
        position: LatLng(s.lat, s.lng),
        icon: icon,
        infoWindow: InfoWindow(
          title: s.name,
          snippet: s.address,
          onTap: () => context.push('/spots/${s.id}'),
        ),
        onTap: () => _selectSpot(s.id),
      );
    }
    final spots = cluster.items.map((it) => it.spot).toList();
    final dominant = SpotPinPainter.dominantCategory(spots);
    final containsSelected =
        _selectedSpotId != null && spots.any((s) => s.id == _selectedSpotId);
    final icon = _resolveClusterPin(
      clusterId: cluster.getId(),
      count: cluster.count,
      color: dominant.color,
      selected: containsSelected,
    );
    return Marker(
      markerId: MarkerId(cluster.getId()),
      position: cluster.location,
      icon: icon,
      onTap: () => _showClusterSheet(cluster, spots),
    );
  }

  // ----- bitmap キャッシュ (同期的に取り出し、未生成なら非同期で作って次の
  // updateMap で差し替える) -----

  BitmapDescriptor _resolveSpotPin(Spot spot, {required bool selected}) {
    final key = 'spot:${spot.id}:sel=$selected';
    final cached = _bitmapCache[key];
    if (cached != null) return cached;
    if (!_bitmapInFlight.contains(key)) {
      _bitmapInFlight.add(key);
      SpotPinPainter.buildSpotPin(
        context: context,
        spot: spot,
        selected: selected,
      ).then(
        (bd) {
          _bitmapCache[key] = bd;
          _bitmapInFlight.remove(key);
          if (!mounted) return;
          _clusterManager?.updateMap();
        },
        onError: (Object _) => _bitmapInFlight.remove(key),
      );
    }
    // 完成までは default marker でつなぐ
    return BitmapDescriptor.defaultMarkerWithHue(_hueFor(spot.primaryCategory));
  }

  BitmapDescriptor _resolveClusterPin({
    required String clusterId,
    required int count,
    required Color color,
    required bool selected,
  }) {
    final key = 'cluster:$clusterId:$count:${color.toARGB32()}:sel=$selected';
    final cached = _bitmapCache[key];
    if (cached != null) return cached;
    if (!_bitmapInFlight.contains(key)) {
      _bitmapInFlight.add(key);
      SpotPinPainter.buildClusterPin(
        context: context,
        count: count,
        color: color,
        selected: selected,
      ).then(
        (bd) {
          _bitmapCache[key] = bd;
          _bitmapInFlight.remove(key);
          if (!mounted) return;
          _clusterManager?.updateMap();
        },
        onError: (Object _) => _bitmapInFlight.remove(key),
      );
    }
    return BitmapDescriptor.defaultMarker;
  }

  // ----- インタラクション -----

  Future<void> _showClusterSheet(
    Cluster<_SpotItem> cluster,
    List<Spot> spots,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return _ClusterSpotsSheet(
          spots: spots,
          onTapSpot: (s) async {
            Navigator.pop(sheetCtx);
            _selectSpot(s.id);
            await _centerOnSpot(s);
          },
          onZoomIn: () async {
            Navigator.pop(sheetCtx);
            await _zoomToCluster(cluster);
          },
        );
      },
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
              padding: const EdgeInsets.only(top: 160, bottom: 32),
              onTap: (_) => _selectSpot(null),
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
          Positioned(
            right: 16,
            bottom: 24,
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

/// クラスタタップで開く、含まれるスポットの一覧シート。
class _ClusterSpotsSheet extends StatelessWidget {
  const _ClusterSpotsSheet({
    required this.spots,
    required this.onTapSpot,
    required this.onZoomIn,
  });

  final List<Spot> spots;
  final ValueChanged<Spot> onTapSpot;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'このエリアのスポット',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${spots.length} 件',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onZoomIn,
                    icon: const Icon(Icons.zoom_in, size: 18),
                    label: const Text('拡大表示'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: spots.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 88, endIndent: 16),
                itemBuilder: (context, i) {
                  final s = spots[i];
                  final firstPhoto =
                      s.photoUrls.isNotEmpty ? s.photoUrls.first : null;
                  return ListTile(
                    onTap: () => onTapSpot(s),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: firstPhoto != null
                            ? CachedNetworkImage(
                                imageUrl: firstPhoto,
                                fit: BoxFit.cover,
                                placeholder: (c, _) => Container(
                                  color: scheme.surfaceContainerHighest,
                                ),
                                errorWidget: (c, _, _) => _CategoryFallback(
                                  category: s.primaryCategory,
                                ),
                              )
                            : _CategoryFallback(category: s.primaryCategory),
                      ),
                    ),
                    title: Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          s.primaryCategory.icon,
                          size: 12,
                          color: s.primaryCategory.color,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            s.address ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: s.rating != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFFFFC107),
                              ),
                              const SizedBox(width: 2),
                              Text(s.rating!.toStringAsFixed(1)),
                            ],
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFallback extends StatelessWidget {
  const _CategoryFallback({required this.category});
  final SpotCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: category.color.withValues(alpha: 0.2),
      child: Icon(category.icon, color: category.color, size: 24),
    );
  }
}
