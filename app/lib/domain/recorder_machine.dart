import 'fix.dart';
import 'geo.dart';
import 'place.dart';
import 'plans.dart';

/// Tunables of the recorder (docs/PLAN.md, A1).
class RecorderConfig {
  const RecorderConfig({
    this.leaveDistanceM = 150,
    this.waitTimeout = const Duration(minutes: 60),
    this.arriveDwell = const Duration(seconds: 60),
    this.intermediateMaxStop = const Duration(minutes: 20),
    this.maxTripDuration = const Duration(hours: 3),
  });

  /// Distance from the arming point that counts as leaving, when the rider
  /// was not inside any known place.
  final double leaveDistanceM;
  final Duration waitTimeout;

  /// Time inside the destination radius before the trip ends.
  final Duration arriveDwell;

  /// A stop at an intermediate place longer than this ends the trip there.
  final Duration intermediateMaxStop;
  final Duration maxTripDuration;
}

// ---------------------------------------------------------------- states

sealed class RecorderState {
  const RecorderState();

  Map<String, Object?> toJson();

  static RecorderState fromJson(Map<String, Object?> j) {
    switch (j['state']) {
      case 'waiting':
        return WaitingState(
          armedAt: (j['armed_at'] as num).toInt(),
          originResolved: j['origin_resolved'] as bool,
          origin: PlaceKind.fromId(j['origin'] as String?),
          anchor: j['anchor_lat'] == null
              ? null
              : LatLng((j['anchor_lat'] as num).toDouble(), (j['anchor_lng'] as num).toDouble()),
          lastInside: j['last_inside'] == null
              ? null
              : Fix.fromJson((j['last_inside'] as Map).cast<String, Object?>()),
        );
      case 'recording':
        return RecordingState(
          tripId: j['trip_id'] as String,
          startedAt: (j['started_at'] as num).toInt(),
          originResolved: j['origin_resolved'] as bool,
          origin: PlaceKind.fromId(j['origin'] as String?),
          arrivalPlace: PlaceKind.fromId(j['arrival_place'] as String?),
          arrivalSince: (j['arrival_since'] as num?)?.toInt(),
        );
      default:
        return const IdleState();
    }
  }
}

class IdleState extends RecorderState {
  const IdleState();

  @override
  Map<String, Object?> toJson() => {'state': 'idle'};
}

/// "Chờ đi": armed with "Sẵn sàng", watching for the rider to leave.
class WaitingState extends RecorderState {
  const WaitingState({
    required this.armedAt,
    this.originResolved = false,
    this.origin,
    this.anchor,
    this.lastInside,
  });

  final int armedAt;

  /// False until the first usable fix decided where the rider is.
  final bool originResolved;
  final PlaceKind? origin;

  /// Arming point, used when the rider is not inside any place.
  final LatLng? anchor;

  /// Latest usable fix still inside the origin; its time is the departure.
  final Fix? lastInside;

  @override
  Map<String, Object?> toJson() => {
        'state': 'waiting',
        'armed_at': armedAt,
        'origin_resolved': originResolved,
        'origin': origin?.id,
        'anchor_lat': anchor?.lat,
        'anchor_lng': anchor?.lng,
        'last_inside': lastInside?.toJson(),
      };
}

/// "Ghi": a trip is being recorded.
class RecordingState extends RecorderState {
  const RecordingState({
    required this.tripId,
    required this.startedAt,
    this.originResolved = true,
    this.origin,
    this.arrivalPlace,
    this.arrivalSince,
  });

  final String tripId;
  final int startedAt;
  final bool originResolved;
  final PlaceKind? origin;

  /// Place the rider is currently inside (other than the origin) and since when.
  final PlaceKind? arrivalPlace;
  final int? arrivalSince;

  RecordingState copyWith({
    bool? originResolved,
    PlaceKind? origin,
    PlaceKind? Function()? arrivalPlace,
    int? Function()? arrivalSince,
  }) =>
      RecordingState(
        tripId: tripId,
        startedAt: startedAt,
        originResolved: originResolved ?? this.originResolved,
        origin: origin ?? this.origin,
        arrivalPlace: arrivalPlace != null ? arrivalPlace() : this.arrivalPlace,
        arrivalSince: arrivalSince != null ? arrivalSince() : this.arrivalSince,
      );

  @override
  Map<String, Object?> toJson() => {
        'state': 'recording',
        'trip_id': tripId,
        'started_at': startedAt,
        'origin_resolved': originResolved,
        'origin': origin?.id,
        'arrival_place': arrivalPlace?.id,
        'arrival_since': arrivalSince,
      };
}

// ---------------------------------------------------------------- inputs

sealed class RecorderInput {
  const RecorderInput(this.now);
  final int now;
}

/// "Sẵn sàng" pressed.
class ArmInput extends RecorderInput {
  const ArmInput(super.now);
}

/// "Ghi ngay" pressed: record immediately.
class StartNowInput extends RecorderInput {
  const StartNowInput(super.now);
}

/// "Hủy" / "Dừng" pressed.
class StopInput extends RecorderInput {
  const StopInput(super.now);
}

class FixInput extends RecorderInput {
  FixInput(this.fix) : super(fix.t);
  final Fix fix;
}

/// Periodic clock tick, for time-outs.
class TickInput extends RecorderInput {
  const TickInput(super.now);
}

// ---------------------------------------------------------------- actions

sealed class RecorderAction {
  const RecorderAction();
}

class StartTripAction extends RecorderAction {
  const StartTripAction({
    required this.tripId,
    required this.startedAt,
    required this.reason,
    required this.origin,
    required this.initialFixes,
  });

  final String tripId;
  final int startedAt;

  /// 'auto' (left the origin after "Sẵn sàng") or 'manual' ("Ghi ngay").
  final String reason;
  final PlaceKind? origin;
  final List<Fix> initialFixes;
}

class AppendFixAction extends RecorderAction {
  const AppendFixAction(this.tripId, this.fix);
  final String tripId;
  final Fix fix;
}

class EndTripAction extends RecorderAction {
  const EndTripAction(this.tripId, this.endedAt, this.reason);
  final String tripId;
  final int endedAt;

  /// 'arrived' | 'long_stop' | 'manual' | 'max_duration'
  final String reason;
}

class CancelWaitingAction extends RecorderAction {
  const CancelWaitingAction(this.reason);

  /// 'manual' | 'timeout'
  final String reason;
}

class RecorderStep {
  const RecorderStep(this.state, [this.actions = const []]);
  final RecorderState state;
  final List<RecorderAction> actions;
}

String tripIdFor(int startedAt) => 't$startedAt';

// ---------------------------------------------------------------- machine

/// Pure transition function of the trip recorder.
RecorderStep stepRecorder(
  RecorderState state,
  RecorderInput input,
  List<Place> places, [
  RecorderConfig cfg = const RecorderConfig(),
]) {
  switch (state) {
    case IdleState():
      return switch (input) {
        ArmInput(:final now) => RecorderStep(WaitingState(armedAt: now)),
        StartNowInput(:final now) => _startNow(now),
        _ => RecorderStep(state),
      };
    case WaitingState():
      return _stepWaiting(state, input, places, cfg);
    case RecordingState():
      return _stepRecording(state, input, places, cfg);
  }
}

RecorderStep _startNow(int now) {
  final id = tripIdFor(now);
  return RecorderStep(
    RecordingState(tripId: id, startedAt: now, originResolved: false),
    [StartTripAction(tripId: id, startedAt: now, reason: 'manual', origin: null, initialFixes: const [])],
  );
}

RecorderStep _stepWaiting(WaitingState s, RecorderInput input, List<Place> places, RecorderConfig cfg) {
  switch (input) {
    case StopInput():
      return const RecorderStep(IdleState(), [CancelWaitingAction('manual')]);
    case StartNowInput(:final now):
      return _startNow(now);
    case ArmInput():
      return RecorderStep(s);
    case TickInput(:final now):
      if (now - s.armedAt >= cfg.waitTimeout.inMilliseconds) {
        return const RecorderStep(IdleState(), [CancelWaitingAction('timeout')]);
      }
      return RecorderStep(s);
    case FixInput(:final fix):
      if (fix.t - s.armedAt >= cfg.waitTimeout.inMilliseconds) {
        return const RecorderStep(IdleState(), [CancelWaitingAction('timeout')]);
      }
      if (!fix.isUsable) return RecorderStep(s);
      if (!s.originResolved) {
        final origin = placeContaining(fix.pos, places);
        return RecorderStep(WaitingState(
          armedAt: s.armedAt,
          originResolved: true,
          origin: origin?.kind,
          anchor: fix.pos,
          lastInside: fix,
        ));
      }
      final originPlace = _find(places, s.origin);
      final inside = originPlace != null
          ? originPlace.contains(fix.pos)
          : distanceM(s.anchor!, fix.pos) <= cfg.leaveDistanceM;
      if (inside) {
        return RecorderStep(WaitingState(
          armedAt: s.armedAt,
          originResolved: true,
          origin: s.origin,
          anchor: s.anchor,
          lastInside: fix,
        ));
      }
      final departure = s.lastInside ?? fix;
      final id = tripIdFor(departure.t);
      return RecorderStep(
        RecordingState(tripId: id, startedAt: departure.t, origin: s.origin),
        [
          StartTripAction(
            tripId: id,
            startedAt: departure.t,
            reason: 'auto',
            origin: s.origin,
            initialFixes: [if (s.lastInside != null) s.lastInside!, fix],
          ),
        ],
      );
  }
}

RecorderStep _stepRecording(RecordingState s, RecorderInput input, List<Place> places, RecorderConfig cfg) {
  switch (input) {
    case StopInput(:final now):
      return RecorderStep(const IdleState(), [EndTripAction(s.tripId, now, 'manual')]);
    case ArmInput() || StartNowInput():
      return RecorderStep(s);
    case TickInput(:final now):
      final ended = _checkTimeouts(s, now, cfg);
      return ended ?? RecorderStep(s);
    case FixInput(:final fix):
      final actions = <RecorderAction>[AppendFixAction(s.tripId, fix)];
      if (!fix.isUsable) return RecorderStep(s, actions);
      var st = s;
      if (!st.originResolved) {
        st = st.copyWith(originResolved: true, origin: placeContaining(fix.pos, places)?.kind);
      }
      final here = placeContaining(fix.pos, places);
      if (here == null || here.kind == st.origin) {
        st = st.copyWith(arrivalPlace: () => null, arrivalSince: () => null);
      } else if (st.arrivalPlace != here.kind) {
        st = st.copyWith(arrivalPlace: () => here.kind, arrivalSince: () => fix.t);
      }
      if (st.arrivalPlace != null) {
        final dwell = fix.t - st.arrivalSince!;
        final intermediate = isIntermediateStop(st.origin, st.arrivalPlace!);
        final limit = intermediate ? cfg.intermediateMaxStop : cfg.arriveDwell;
        if (dwell >= limit.inMilliseconds) {
          return RecorderStep(const IdleState(), [
            ...actions,
            EndTripAction(st.tripId, st.arrivalSince!, intermediate ? 'long_stop' : 'arrived'),
          ]);
        }
      }
      final ended = _checkTimeouts(st, fix.t, cfg);
      if (ended != null) return RecorderStep(ended.state, [...actions, ...ended.actions]);
      return RecorderStep(st, actions);
  }
}

RecorderStep? _checkTimeouts(RecordingState s, int now, RecorderConfig cfg) {
  if (now - s.startedAt >= cfg.maxTripDuration.inMilliseconds) {
    return RecorderStep(const IdleState(), [EndTripAction(s.tripId, now, 'max_duration')]);
  }
  return null;
}

Place? _find(List<Place> places, PlaceKind? kind) {
  if (kind == null) return null;
  for (final p in places) {
    if (p.kind == kind) return p;
  }
  return null;
}
