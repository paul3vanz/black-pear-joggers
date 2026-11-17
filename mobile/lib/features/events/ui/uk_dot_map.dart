import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Rough outline of Great Britain as (lat, lng) points: just enough to show
/// roughly where an event is. Not a survey; no map package or API key needed.
const _gbOutline = <(double, double)>[
  (58.65, -3.0),
  (58.6, -5.0),
  (57.5, -5.8),
  (57.0, -6.2),
  (56.4, -5.6),
  (55.7, -5.8),
  (55.3, -5.0),
  (54.8, -5.0),
  (54.7, -3.6),
  (54.0, -3.0),
  (53.4, -3.1),
  (53.3, -4.5),
  (52.8, -4.7),
  (52.2, -4.2),
  (51.8, -5.2),
  (51.6, -3.5),
  (51.2, -3.2),
  (51.2, -4.2),
  (50.6, -4.6),
  (50.05, -5.7),
  (50.6, -2.5),
  (50.75, -1.2),
  (50.8, 0.3),
  (51.1, 1.4),
  (51.4, 1.4),
  (51.5, 0.7),
  (51.7, 1.0),
  (52.0, 1.7),
  (52.7, 1.7),
  (53.0, 0.3),
  (53.6, 0.1),
  (54.1, -0.2),
  (54.6, -1.1),
  (55.5, -1.6),
  (56.0, -2.6),
  (56.5, -2.5),
  (57.6, -1.8),
  (57.7, -3.8),
  (58.4, -3.1),
];

/// True when the point sits inside the map's UK extent.
bool isInUkExtent(double lat, double lng) =>
    lat >= 49.8 && lat <= 59.0 && lng >= -8.0 && lng <= 2.0;

/// A small outline of Great Britain with a dot at ([lat], [lng]).
class UkDotMap extends StatelessWidget {
  const UkDotMap({super.key, required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Map of Great Britain showing roughly where this event is',
      child: SizedBox(
        width: 72,
        height: 100,
        child: CustomPaint(
          painter: _UkPainter(
            lat,
            lng,
            outline: scheme.outline,
            fill: scheme.surfaceContainerHighest,
            dot: scheme.primary,
          ),
        ),
      ),
    );
  }
}

class _UkPainter extends CustomPainter {
  _UkPainter(
    this.lat,
    this.lng, {
    required this.outline,
    required this.fill,
    required this.dot,
  });

  final double lat;
  final double lng;
  final Color outline;
  final Color fill;
  final Color dot;

  static const _minLat = 49.8, _maxLat = 58.8, _minLng = -6.4, _maxLng = 1.9;

  Offset _project(double la, double ln, Size size) {
    // Longitude degrees are shorter than latitude ones at ~54 N.
    final k = math.cos(54 * math.pi / 180);
    final w = (_maxLng - _minLng) * k, h = _maxLat - _minLat;
    final scale = math.min(size.width / w, size.height / h);
    final dx = (size.width - w * scale) / 2, dy = (size.height - h * scale) / 2;
    return Offset(dx + (ln - _minLng) * k * scale, dy + (_maxLat - la) * scale);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < _gbOutline.length; i++) {
      final p = _project(_gbOutline[i].$1, _gbOutline[i].$2, size);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round,
    );
    final c = _project(lat, lng, size);
    canvas.drawCircle(c, 5, Paint()..color = dot.withValues(alpha: 0.3));
    canvas.drawCircle(c, 3, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_UkPainter old) =>
      old.lat != lat || old.lng != lng || old.dot != dot || old.fill != fill;
}
