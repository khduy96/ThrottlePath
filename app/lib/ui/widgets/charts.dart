import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/fix.dart';
import '../../domain/geo.dart';
import '../../domain/place.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Speed → colour ramp used by the trace and its legend.
const _speedStops = [
  (0.0, Color(0xFFDC2626)), // stopped / jammed
  (10.0, Color(0xFFF97316)),
  (20.0, Color(0xFFEAB308)),
  (30.0, Color(0xFF22C55E)),
  (40.0, Color(0xFF14B8A6)),
];

Color speedColor(double kmh) {
  if (kmh <= _speedStops.first.$1) return _speedStops.first.$2;
  for (var i = 1; i < _speedStops.length; i++) {
    final (v1, c1) = _speedStops[i];
    if (kmh <= v1) {
      final (v0, c0) = _speedStops[i - 1];
      return Color.lerp(c0, c1, (kmh - v0) / (v1 - v0))!;
    }
  }
  return _speedStops.last.$2;
}

/// Draws the user's own GPS trace (not a map) coloured by speed, with the
/// saved places as circles. Aspect follows the trace's bounding box.
class TraceView extends StatelessWidget {
  const TraceView({super.key, required this.fixes, this.places = const []});

  final List<Fix> fixes;
  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    if (fixes.length < 2) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text('Chưa đủ điểm GPS để vẽ tuyến', style: TextStyle(color: context.cs.onSurfaceVariant)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.1,
          child: CustomPaint(
            painter: _TracePainter(
              fixes: fixes,
              places: places,
              grid: context.cs.outlineVariant.withValues(alpha: 0.5),
              casing: context.cs.surface,
              placeColor: context.cs.primary,
              startColor: context.colors.success,
              endColor: context.cs.onSurface,
              labelStyle: context.text.labelSmall!.copyWith(color: context.cs.onSurfaceVariant),
            ),
          ),
        ),
        const SizedBox(height: Gap.md),
        const _SpeedLegend(),
      ],
    );
  }
}

class _SpeedLegend extends StatelessWidget {
  const _SpeedLegend();

  @override
  Widget build(BuildContext context) {
    final style = context.text.labelSmall?.copyWith(color: context.cs.onSurfaceVariant);
    return Row(
      children: [
        Text('Kẹt', style: style),
        const SizedBox(width: Gap.sm),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: LinearGradient(colors: [for (final s in _speedStops) s.$2]),
            ),
          ),
        ),
        const SizedBox(width: Gap.sm),
        Text('40+ km/h', style: style),
      ],
    );
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter({
    required List<Fix> fixes,
    required this.places,
    required this.grid,
    required this.casing,
    required this.placeColor,
    required this.startColor,
    required this.endColor,
    required this.labelStyle,
  }) : fixes = _downsample(fixes, 1500);

  final List<Fix> fixes;
  final List<Place> places;
  final Color grid;
  final Color casing;
  final Color placeColor;
  final Color startColor;
  final Color endColor;
  final TextStyle labelStyle;

  static List<Fix> _downsample(List<Fix> f, int max) {
    if (f.length <= max) return f;
    final step = f.length / max;
    return [for (var i = 0.0; i < f.length; i += step) f[i.floor()], f.last];
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Equirectangular projection around the trace centre, in metres.
    var minLat = double.infinity, maxLat = -double.infinity;
    var minLng = double.infinity, maxLng = -double.infinity;
    for (final f in fixes) {
      minLat = math.min(minLat, f.lat);
      maxLat = math.max(maxLat, f.lat);
      minLng = math.min(minLng, f.lng);
      maxLng = math.max(maxLng, f.lng);
    }
    final midLat = (minLat + maxLat) / 2;
    final kx = 111320 * math.cos(midLat * math.pi / 180);
    const ky = 110540.0;
    final wA = (maxLng - minLng) * kx;
    final hA = (maxLat - minLat) * ky;
    const pad = 28.0;
    final scale = math.min((size.width - 2 * pad) / math.max(wA, 50), (size.height - 2 * pad) / math.max(hA, 50));
    // Centre the trace's bounding box in the canvas.
    final ox = (size.width - wA * scale) / 2;
    final oy = (size.height - hA * scale) / 2;
    Offset p(double lat, double lng) => Offset(ox + (lng - minLng) * kx * scale, oy + (maxLat - lat) * ky * scale);

    // Background grid, one line every ~500 m.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    final step = 500 * scale;
    if (step > 12) {
      for (var x = size.width / 2 % step; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (var y = size.height / 2 % step; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // Places inside (or near) the view.
    for (final pl in places) {
      final c = p(pl.pos.lat, pl.pos.lng);
      if (c.dx < -50 || c.dy < -50 || c.dx > size.width + 50 || c.dy > size.height + 50) continue;
      final r = math.max(pl.radiusM * scale, 10.0);
      canvas.drawCircle(c, r, Paint()..color = placeColor.withValues(alpha: 0.12));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = placeColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final icon = placeIcon(pl.kind);
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: 16, color: placeColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
      final label = TextPainter(text: TextSpan(text: pl.name, style: labelStyle), textDirection: TextDirection.ltr)
        ..layout();
      label.paint(canvas, c + Offset(-label.width / 2, r + 2));
    }

    final pts = [for (final f in fixes) p(f.lat, f.lng)];

    // Casing under the coloured line so it reads on the grid.
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final o in pts.skip(1)) {
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = casing
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final seg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < fixes.length; i++) {
      final a = fixes[i - 1], b = fixes[i];
      double kmh;
      if (b.speedMps != null) {
        kmh = b.speedMps! * 3.6;
      } else {
        final dt = (b.t - a.t) / 1000;
        kmh = dt <= 0 ? 0 : distanceM(LatLng(a.lat, a.lng), LatLng(b.lat, b.lng)) / dt * 3.6;
      }
      seg.color = speedColor(kmh);
      canvas.drawLine(pts[i - 1], pts[i], seg);
    }

    void endpoint(Offset o, Color fill) {
      canvas.drawCircle(o, 9, Paint()..color = casing);
      canvas.drawCircle(o, 6.5, Paint()..color = fill);
    }

    endpoint(pts.first, startColor);
    endpoint(pts.last, endColor);
  }

  @override
  bool shouldRepaint(_TracePainter old) =>
      old.fixes != fixes || old.places != places || old.grid != grid || old.casing != casing;
}

/// One bar in [MinutesChart].
class ChartBar {
  const ChartBar({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;
}

/// Simple bar chart of trip minutes with a dashed median line.
class MinutesChart extends StatelessWidget {
  const MinutesChart({super.key, required this.bars, this.height = 140});

  final List<ChartBar> bars;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();
    final sorted = [for (final b in bars) b.value]..sort();
    final median = sorted.length.isOdd
        ? sorted[sorted.length ~/ 2]
        : (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2;
    final maxV = math.max(sorted.last, 1.0) * 1.15;
    final labelStyle = context.text.labelSmall?.copyWith(color: context.cs.onSurfaceVariant, fontFeatures: tabular);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, c) {
              final medianY = c.maxHeight * (1 - median / maxV);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < bars.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: bars[i].value / maxV),
                            duration: Duration(milliseconds: 500 + i * 30),
                            curve: Curves.easeOutCubic,
                            builder: (context, f, _) => Container(
                              height: math.max(c.maxHeight * f, 4),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(2)),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [bars[i].color, bars[i].color.withValues(alpha: 0.55)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: medianY,
                    child: CustomPaint(painter: _DashPainter(context.cs.onSurface.withValues(alpha: 0.55))),
                  ),
                  Positioned(
                    right: 0,
                    top: medianY - 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('trung vị ${median.round()}′', style: labelStyle),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < bars.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Text(bars[i].label, textAlign: TextAlign.center, maxLines: 1, style: labelStyle),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + 4, size.width), 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
