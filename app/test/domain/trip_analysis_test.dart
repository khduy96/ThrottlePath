import 'package:flutter_test/flutter_test.dart';
import 'package:throttle_path/domain/place.dart';
import 'package:throttle_path/domain/plans.dart';
import 'package:throttle_path/domain/trip_analysis.dart';

import 'fake_route.dart';

void main() {
  // Morning: home → stop (2 min) → work.
  final leg1 = ride(homePos, stopPos, t0);
  final atStop = stay(stopPos, leg1.last.t + 5000, 120);
  final leg2 = ride(stopPos, workPos, atStop.last.t + 5000);
  final morning = [...leg1, ...atStop, ...leg2];

  test('detectPlan', () {
    expect(detectPlan(morning, places)!.plan, PlanId.morning);
    expect(detectPlan(morning, places)!.partial, isFalse);
    expect(detectPlan(ride(workPos, stopPos, t0), places)!.plan, PlanId.evening1);
    expect(detectPlan(ride(stopPos, homePos, t0), places)!.plan, PlanId.evening2);

    final partial = detectPlan(ride(homePos, stopPos, t0), places)!;
    expect(partial.plan, PlanId.morning);
    expect(partial.partial, isTrue);

    expect(detectPlan(ride(north(homePos, -3000), north(homePos, -6000), t0), places), isNull);
  });

  test('splitTraceByLegs: morning splits at Cửa Hàng with the stop time', () {
    final endedAt = morning.last.t;
    final legs = splitTraceByLegs(morning, PlanId.morning, places, t0, endedAt)!;
    expect(legs, hasLength(2));
    expect(legs[0].from, PlaceKind.home);
    expect(legs[0].to, PlaceKind.stop);
    expect(legs[1].from, PlaceKind.stop);
    expect(legs[1].to, PlaceKind.work);

    final enterStop = leg1.firstWhere((f) => places[1].contains(f.pos)).t;
    expect(legs[0].endT, enterStop);
    // Stay of ~2 min plus riding time inside the 100 m radius.
    expect(legs[0].stopMin!, inInclusiveRange(2.0, 2.6));
    expect(legs[1].startT, greaterThan(legs[0].endT));
    expect(legs[1].endT, endedAt);
    final total = legs[0].actualMin + legs[0].stopMin! + legs[1].actualMin;
    expect(total, closeTo((endedAt - t0) / 60000, 1e-9));
  });

  test('splitTraceByLegs: no visit to the intermediate place → null', () {
    final direct = ride(homePos, north(workPos, 0), t0)
        .where((f) => !places[1].contains(f.pos))
        .toList();
    expect(splitTraceByLegs(direct, PlanId.morning, places, t0, direct.last.t), isNull);
  });

  test('single-leg plan', () {
    final trip = ride(stopPos, homePos, t0);
    final legs = splitTraceByLegs(trip, PlanId.evening2, places, t0, trip.last.t)!;
    expect(legs.single.from, PlaceKind.stop);
    expect(legs.single.to, PlaceKind.home);
  });

  test('distance, too-short filter, stats', () {
    final d = traceDistanceM(leg1);
    expect(d, closeTo(2224, 30)); // 0.02° lat ≈ 2.22 km
    expect(isTooShort(leg1, t0, leg1.last.t), isFalse);
    expect(isTooShort(stay(homePos, t0, 600), t0, t0 + 600000), isTrue);
    expect(isTooShort(leg1, t0, t0 + 60000), isTrue);

    final s = tripStats(leg1, t0, leg1.last.t);
    expect(s.avgSpeedKmh, closeTo(8 * 3.6, 2));
    expect(s.maxSpeedKmh, closeTo(28.8, 0.01));
    expect(s.pointCount, leg1.length);
  });
}
