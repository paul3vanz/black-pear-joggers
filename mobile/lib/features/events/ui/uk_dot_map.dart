import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Outline of Great Britain's coast as (lat, lng) points (a few hundred metres of
/// accuracy is not claimed): enough to show where an event is. Not a survey; no map package or API key needed.
const _gbOutline = <(double, double)>[
  (58.67, -3.37),
  (58.64, -3.07),
  (58.44, -3.08),
  (58.12, -3.65),
  (57.95, -3.95),
  (57.82, -4.05),
  (57.86, -3.78),
  (57.68, -4.04),
  (57.5, -4.2),
  (57.59, -3.87),
  (57.70, -3.5),
  (57.72, -3.28),
  (57.69, -2.82),
  (57.69, -2.0),
  (57.5, -1.78),
  (57.14, -2.07),
  (56.96, -2.2),
  (56.71, -2.46),
  (56.56, -2.58),
  (56.46, -2.97),
  (56.34, -2.8),
  (56.28, -2.58),
  (56.19, -2.8),
  (56.11, -3.15),
  (55.98, -3.2),
  (56.06, -2.72),
  (56.0, -2.52),
  (55.9, -2.14),
  (55.77, -2.0),
  (55.67, -1.8),
  (55.6, -1.7),
  (55.33, -1.57),
  (55.01, -1.42),
  (54.9, -1.38),
  (54.69, -1.18),
  (54.62, -1.15),
  (54.49, -0.61),
  (54.28, -0.4),
  (54.12, -0.08),
  (54.08, -0.19),
  (53.9, 0.1),
  (53.58, 0.12),
  (53.58, -0.07),
  (53.15, 0.35),
  (52.97, 0.02),
  (52.8, 0.4),
  (52.95, 0.49),
  (52.96, 0.85),
  (52.93, 1.3),
  (52.82, 1.53),
  (52.6, 1.73),
  (52.48, 1.76),
  (52.32, 1.68),
  (52.08, 1.6),
  (51.96, 1.35),
  (51.94, 1.28),
  (51.79, 1.15),
  (51.78, 0.95),
  (51.58, 0.95),
  (51.53, 0.72),
  (51.44, 0.77),
  (51.36, 1.03),
  (51.39, 1.38),
  (51.33, 1.42),
  (51.22, 1.4),
  (51.13, 1.31),
  (51.08, 1.17),
  (50.91, 0.97),
  (50.85, 0.58),
  (50.73, 0.25),
  (50.82, -0.14),
  (50.81, -0.37),
  (50.72, -0.79),
  (50.8, -1.05),
  (50.82, -1.3),
  (50.75, -1.53),
  (50.72, -1.88),
  (50.6, -1.95),
  (50.55, -2.45),
  (50.72, -2.93),
  (50.62, -3.4),
  (50.45, -3.5),
  (50.22, -3.64),
  (50.21, -3.77),
  (50.36, -4.14),
  (50.35, -4.45),
  (50.33, -4.65),
  (50.22, -4.8),
  (50.15, -5.05),
  (49.96, -5.2),
  (50.12, -5.53),
  (50.07, -5.72),
  (50.21, -5.48),
  (50.42, -5.08),
  (50.55, -4.95),
  (50.67, -4.76),
  (50.83, -4.55),
  (50.99, -4.53),
  (51.05, -4.2),
  (51.21, -4.12),
  (51.23, -3.83),
  (51.2, -3.47),
  (51.21, -3.13),
  (51.35, -2.98),
  (51.5, -2.7),
  (51.64, -2.67),
  (51.55, -2.97),
  (51.46, -3.17),
  (51.4, -3.3),
  (51.47, -3.7),
  (51.6, -3.95),
  (51.55, -4.3),
  (51.67, -4.2),
  (51.67, -4.7),
  (51.6, -4.95),
  (51.7, -5.05),
  (51.68, -5.17),
  (51.88, -5.3),
  (52.0, -4.98),
  (52.1, -4.7),
  (52.24, -4.26),
  (52.41, -4.09),
  (52.54, -4.05),
  (52.72, -4.05),
  (52.86, -4.12),
  (52.88, -4.4),
  (52.79, -4.74),
  (53.14, -4.28),
  (53.31, -4.63),
  (53.42, -4.33),
  (53.27, -4.09),
  (53.3, -3.83),
  (53.33, -3.83),
  (53.32, -3.5),
  (53.34, -3.4),
  (53.25, -3.13),
  (53.4, -3.18),
  (53.4, -3.0),
  (53.65, -3.02),
  (53.82, -3.05),
  (53.93, -3.0),
  (54.07, -2.86),
  (54.1, -3.2),
  (54.35, -3.42),
  (54.5, -3.6),
  (54.72, -3.5),
  (54.87, -3.4),
  (54.95, -3.0),
  (54.9, -3.5),
  (54.82, -4.05),
  (54.85, -4.4),
  (54.63, -4.85),
  (54.9, -5.03),
  (55.0, -5.15),
  (55.1, -5.0),
  (55.24, -4.86),
  (55.46, -4.63),
  (55.64, -4.82),
  (55.8, -4.87),
  (55.95, -4.77),
  (55.95, -4.92),
  (55.31, -5.8),
  (55.42, -5.7),
  (55.75, -5.7),
  (56.09, -5.55),
  (56.4, -5.47),
  (56.73, -6.2),
  (57.0, -5.83),
  (57.28, -5.72),
  (57.9, -5.17),
  (58.15, -5.25),
  (58.63, -5.0),
  (58.57, -4.75),
  (58.5, -4.4),
  (58.6, -3.5),
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
        width: 110,
        height: 150,
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
