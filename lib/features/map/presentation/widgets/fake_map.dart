import 'package:flutter/material.dart';
import 'package:polaris/features/spots/models/spot.dart';
import 'package:polaris/features/spots/models/spot_category_x.dart';

class FakeMap extends StatelessWidget {
  const FakeMap({
    required this.spots,
    required this.onSpotTap,
    this.selectedSpotId,
    super.key,
  });

  final List<Spot> spots;
  final ValueChanged<Spot> onSpotTap;
  final String? selectedSpotId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (spots.isEmpty) {
          return const _MapBackground(child: SizedBox.expand());
        }
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        var minLat = double.infinity;
        var maxLat = -double.infinity;
        var minLng = double.infinity;
        var maxLng = -double.infinity;
        for (final s in spots) {
          if (s.lat < minLat) minLat = s.lat;
          if (s.lat > maxLat) maxLat = s.lat;
          if (s.lng < minLng) minLng = s.lng;
          if (s.lng > maxLng) maxLng = s.lng;
        }
        if ((maxLat - minLat) < 0.005) {
          minLat -= 0.0025;
          maxLat += 0.0025;
        }
        if ((maxLng - minLng) < 0.005) {
          minLng -= 0.0025;
          maxLng += 0.0025;
        }
        const pad = 60.0;
        final usableW = w - pad * 2;
        final usableH = h - pad * 2;
        return _MapBackground(
          child: Stack(
            children: [
              for (final s in spots)
                Positioned(
                  left:
                      pad +
                      ((s.lng - minLng) / (maxLng - minLng)) * usableW -
                      20,
                  top:
                      pad +
                      (1 - (s.lat - minLat) / (maxLat - minLat)) * usableH -
                      40,
                  child: _Pin(
                    spot: s,
                    selected: s.id == selectedSpotId,
                    onTap: () => onSpotTap(s),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MapBackground extends StatelessWidget {
  const _MapBackground({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.surfaceContainerLowest,
            scheme.surfaceContainerLow,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: _MapPainter(scheme: scheme),
        child: child,
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.scheme});
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    const step = 40.0;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    // Stylized roads
    final road = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final p1 = Path()
      ..moveTo(size.width * 0.05, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.1,
        size.width * 0.95,
        size.height * 0.32,
      );
    final p2 = Path()
      ..moveTo(size.width * 0.18, size.height * 0.95)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.6,
        size.width * 0.6,
        size.height * 0.55,
        size.width * 0.85,
        size.height * 0.05,
      );
    final p3 = Path()
      ..moveTo(0, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 0.74,
        size.width,
        size.height * 0.55,
      );
    canvas
      ..drawPath(p1, road)
      ..drawPath(p2, road)
      ..drawPath(p3, road);
    // Subtle parks (green blobs)
    final park = Paint()
      ..color = const Color(0xFF66BB6A).withValues(alpha: 0.13);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.7),
      size.width * 0.18,
      park,
    );
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.4),
      size.width * 0.12,
      park,
    );
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => false;
}

class _Pin extends StatelessWidget {
  const _Pin({
    required this.spot,
    required this.selected,
    required this.onTap,
  });

  final Spot spot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = spot.primaryCategory.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.18 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: selected ? 0.3 : 0.18,
                      ),
                      blurRadius: selected ? 12 : 6,
                      offset: Offset(0, selected ? 5 : 2),
                    ),
                  ],
                ),
                child: Icon(
                  spot.primaryCategory.icon,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              if (spot.wantToVisit)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E63),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
