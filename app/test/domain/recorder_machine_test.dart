import 'package:flutter_test/flutter_test.dart';
import 'package:throttle_path/domain/fix.dart';
import 'package:throttle_path/domain/place.dart';
import 'package:throttle_path/domain/recorder_machine.dart';

import 'fake_route.dart';

/// Feeds inputs through the machine, collecting all actions.
(RecorderState, List<RecorderAction>) run(RecorderState s, Iterable<RecorderInput> inputs) {
  final actions = <RecorderAction>[];
  for (final i in inputs) {
    final step = stepRecorder(s, i, places);
    s = step.state;
    actions.addAll(step.actions);
  }
  return (s, actions);
}

Iterable<FixInput> fixes(List<Fix> list) => list.map(FixInput.new);

void main() {
  test('arm at home, wait, leave → trip starts at last fix inside home', () {
    final waitFixes = stay(homePos, t0, 300, stepS: 10);
    final lastInside = waitFixes.last;
    final leaving = ride(homePos, north(homePos, 400), lastInside.t + 10000);
    final (s, actions) = run(const IdleState(), [const ArmInput(t0), ...fixes(waitFixes), ...fixes(leaving)]);

    expect(s, isA<RecordingState>());
    final start = actions.whereType<StartTripAction>().single;
    expect(start.reason, 'auto');
    expect(start.origin, PlaceKind.home);
    expect(start.startedAt, greaterThanOrEqualTo(lastInside.t));
    expect(start.initialFixes, isNotEmpty);
    expect((s as RecordingState).tripId, start.tripId);
  });

  test('inaccurate fixes do not trigger departure', () {
    final (s, actions) = run(const IdleState(), [
      const ArmInput(t0),
      FixInput(fixAt(homePos, t0 + 1000)),
      FixInput(fixAt(north(homePos, 500), t0 + 11000, acc: 200)),
    ]);
    expect(s, isA<WaitingState>());
    expect(actions, isEmpty);
  });

  test('waiting times out after 60 minutes', () {
    final (s, actions) = run(const IdleState(), [
      const ArmInput(t0),
      FixInput(fixAt(homePos, t0 + 1000)),
      const TickInput(t0 + 61 * 60000),
    ]);
    expect(s, isA<IdleState>());
    expect((actions.single as CancelWaitingAction).reason, 'timeout');
  });

  test('cancel while waiting', () {
    final (s, actions) = run(const IdleState(), [const ArmInput(t0), const StopInput(t0 + 5000)]);
    expect(s, isA<IdleState>());
    expect((actions.single as CancelWaitingAction).reason, 'manual');
  });

  test('not inside any place: leaving 150 m from the arming point starts the trip', () {
    final anywhere = north(homePos, 5000);
    final (s, actions) = run(const IdleState(), [
      const ArmInput(t0),
      FixInput(fixAt(anywhere, t0 + 1000)),
      FixInput(fixAt(north(anywhere, 100), t0 + 11000)),
      FixInput(fixAt(north(anywhere, 200), t0 + 21000)),
    ]);
    expect(s, isA<RecordingState>());
    final start = actions.whereType<StartTripAction>().single;
    expect(start.origin, isNull);
    expect(start.startedAt, t0 + 11000);
  });

  test('morning: stop at Cửa Hàng does not end the trip; arriving at work does', () {
    var t = t0;
    final leg1 = ride(homePos, stopPos, t);
    t = leg1.last.t + 5000;
    final atStop = stay(stopPos, t, 120);
    t = atStop.last.t + 5000;
    final leg2 = ride(stopPos, workPos, t);
    t = leg2.last.t + 5000;
    final atWork = stay(workPos, t, 90);

    final (s, actions) = run(const IdleState(), [
      const ArmInput(t0 - 60000),
      FixInput(fixAt(homePos, t0 - 50000)),
      ...fixes(leg1),
      ...fixes(atStop),
      ...fixes(leg2),
    ]);
    expect(s, isA<RecordingState>(), reason: '2-minute stop at Cửa Hàng must not end the trip');
    expect(actions.whereType<EndTripAction>(), isEmpty);

    final (s2, more) = run(s, fixes(atWork));
    expect(s2, isA<IdleState>());
    final end = more.whereType<EndTripAction>().single;
    expect(end.reason, 'arrived');
    // Ends at the arrival time, not after the 60 s dwell.
    final firstInside = leg2.firstWhere((f) => places[2].contains(f.pos));
    expect(end.endedAt, firstInside.t);
  });

  test('evening 1: Cửa Hàng is the destination when starting from work', () {
    final leg = ride(workPos, stopPos, t0);
    final (s, actions) = run(const IdleState(), [
      const ArmInput(t0 - 20000),
      FixInput(fixAt(workPos, t0 - 10000)),
      ...fixes(leg),
      ...fixes(stay(stopPos, leg.last.t + 5000, 70)),
    ]);
    expect(s, isA<IdleState>());
    expect(actions.whereType<EndTripAction>().single.reason, 'arrived');
  });

  test('long stop at an intermediate place ends the trip there', () {
    final leg = ride(homePos, stopPos, t0);
    final (s, actions) = run(const IdleState(), [
      const ArmInput(t0 - 20000),
      FixInput(fixAt(homePos, t0 - 10000)),
      ...fixes(leg),
      ...fixes(stay(stopPos, leg.last.t + 5000, 21 * 60, stepS: 30)),
    ]);
    expect(s, isA<IdleState>());
    expect(actions.whereType<EndTripAction>().single.reason, 'long_stop');
  });

  test('manual stop and max duration', () {
    final started = run(const IdleState(), [const StartNowInput(t0)]);
    expect(started.$1, isA<RecordingState>());
    expect(started.$2.whereType<StartTripAction>().single.reason, 'manual');

    final stopped = run(started.$1, [const StopInput(t0 + 60000)]);
    expect(stopped.$2.whereType<EndTripAction>().single.reason, 'manual');

    final timedOut = run(started.$1, [const TickInput(t0 + 3 * 3600000)]);
    expect(timedOut.$2.whereType<EndTripAction>().single.reason, 'max_duration');
  });

  test('"Ghi ngay" at home resolves the origin from the first fix', () {
    final leg = ride(homePos, workPos, t0 + 5000);
    final (s, _) = run(const IdleState(), [
      const StartNowInput(t0),
      FixInput(fixAt(homePos, t0 + 1000)),
      ...fixes(leg.take(10).toList()),
    ]);
    expect((s as RecordingState).origin, PlaceKind.home);
  });

  test('state survives a JSON round trip', () {
    final states = <RecorderState>[
      const IdleState(),
      WaitingState(armedAt: t0, originResolved: true, origin: PlaceKind.home, anchor: homePos, lastInside: fixAt(homePos, t0)),
      const RecordingState(tripId: 't1', startedAt: t0, origin: PlaceKind.work, arrivalPlace: PlaceKind.stop, arrivalSince: t0 + 5),
    ];
    for (final st in states) {
      expect(RecorderState.fromJson(st.toJson()).toJson(), st.toJson());
    }
  });
}
