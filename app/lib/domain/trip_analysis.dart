import 'fix.dart';
import 'geo.dart';
import 'place.dart';
import 'plans.dart';

/// Trips shorter than this are dropped (riding around near home).
const Duration minTripDuration = Duration(minutes: 2);
const double minTripDistanceM = 300;

/// Distance along usable fixes, in metres.
double traceDistanceM(List<Fix> fixes) {
  var total = 0.0;
  Fix? prev;
  for (final f in fixes) {
    if (!f.isUsable) continue;
    if (prev != null) total += distanceM(prev.pos, f.pos);
    prev = f;
  }
  return total;
}

bool isTooShort(List<Fix> fixes, int startedAt, int endedAt) =>
    endedAt - startedAt < minTripDuration.inMilliseconds || traceDistanceM(fixes) < minTripDistanceM;

class PlanMatch {
  const PlanMatch(this.plan, {this.partial = false});
  final PlanId plan;

  /// The trip ended at an intermediate place (e.g. Nhà → Cửa Hàng only).
  final bool partial;
}

PlaceKind? _placeAt(Fix f, List<Place> places) => placeContaining(f.pos, places)?.kind;

PlaceKind? _firstPlace(Iterable<Fix> fixes, List<Place> places) {
  for (final f in fixes) {
    if (!f.isUsable) continue;
    return _placeAt(f, places);
  }
  return null;
}

/// Guesses which plan a trip belongs to from its first and last place.
PlanMatch? detectPlan(List<Fix> fixes, List<Place> places) {
  final origin = _firstPlace(fixes, places);
  final dest = _firstPlace(fixes.reversed, places);
  if (origin == null || dest == null || origin == dest) return null;
  for (final plan in PlanId.values) {
    if (plan.origin == origin && plan.destination == dest) return PlanMatch(plan);
  }
  for (final plan in PlanId.values) {
    if (plan.origin == origin && plan.intermediates.contains(dest)) {
      return PlanMatch(plan, partial: true);
    }
  }
  return null;
}

class LegResult {
  const LegResult({
    required this.from,
    required this.to,
    required this.startT,
    required this.endT,
    this.stopMin,
  });

  final PlaceKind from;
  final PlaceKind to;
  final int startT;
  final int endT;

  /// Time spent inside [to] before the next leg (intermediate places only).
  final double? stopMin;

  double get actualMin => (endT - startT) / 60000;

  Map<String, Object?> toJson() => {
        'from': from.id,
        'to': to.id,
        'start': startT,
        'end': endT,
        'actual_min': actualMin,
        if (stopMin != null) 'stop_min': stopMin,
      };

  static LegResult fromJson(Map<String, Object?> j) => LegResult(
        from: PlaceKind.fromId(j['from'] as String)!,
        to: PlaceKind.fromId(j['to'] as String)!,
        startT: (j['start'] as num).toInt(),
        endT: (j['end'] as num).toInt(),
        stopMin: (j['stop_min'] as num?)?.toDouble(),
      );
}

/// Cuts a trip at the plan's intermediate places. Returns null when an
/// intermediate place was not visited (the trip total is still kept).
/// [endedAt] is the arrival time at the destination.
List<LegResult>? splitTraceByLegs(List<Fix> fixes, PlanId plan, List<Place> places, int startedAt, int endedAt) {
  final byKind = {for (final p in places) p.kind: p};
  final legs = <LegResult>[];
  var legStart = startedAt;
  var i = 0;
  for (var k = 0; k < plan.intermediates.length; k++) {
    final place = byKind[plan.intermediates[k]];
    if (place == null) return null;
    // First usable fix inside the intermediate place.
    while (i < fixes.length && !(fixes[i].isUsable && place.contains(fixes[i].pos))) {
      i++;
    }
    if (i >= fixes.length) return null;
    final enter = fixes[i].t;
    // Last fix of the contiguous stay inside it.
    var exit = enter;
    while (i < fixes.length && (!fixes[i].isUsable || place.contains(fixes[i].pos))) {
      if (fixes[i].isUsable) exit = fixes[i].t;
      i++;
    }
    final from = plan.places[k];
    legs.add(LegResult(
      from: from,
      to: place.kind,
      startT: legStart,
      endT: enter,
      stopMin: (exit - enter) / 60000,
    ));
    legStart = exit;
  }
  legs.add(LegResult(
    from: plan.places[plan.places.length - 2],
    to: plan.destination,
    startT: legStart,
    endT: endedAt,
  ));
  return legs;
}

class TripStats {
  const TripStats({
    required this.distanceM,
    required this.pointCount,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.avgAccuracyM,
  });

  final double distanceM;
  final int pointCount;
  final double avgSpeedKmh;
  final double? maxSpeedKmh;
  final double? avgAccuracyM;
}

TripStats tripStats(List<Fix> fixes, int startedAt, int endedAt) {
  final dist = traceDistanceM(fixes);
  final hours = (endedAt - startedAt) / 3600000;
  double? maxSpeed;
  var accSum = 0.0;
  var accN = 0;
  for (final f in fixes) {
    if (f.speedMps != null && f.isUsable) {
      final kmh = f.speedMps! * 3.6;
      if (maxSpeed == null || kmh > maxSpeed) maxSpeed = kmh;
    }
    if (f.accuracyM != null) {
      accSum += f.accuracyM!;
      accN++;
    }
  }
  return TripStats(
    distanceM: dist,
    pointCount: fixes.length,
    avgSpeedKmh: hours > 0 ? dist / 1000 / hours : 0,
    maxSpeedKmh: maxSpeed,
    avgAccuracyM: accN > 0 ? accSum / accN : null,
  );
}
