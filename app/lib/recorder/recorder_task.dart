import 'dart:async';
import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../data/database.dart';
import '../domain/fix.dart';
import '../domain/geo.dart';
import '../domain/place.dart';
import '../domain/recorder_machine.dart';
import 'protocol.dart';

/// Entry point of the foreground service isolate.
@pragma('vm:entry-point')
void recorderCallback() {
  FlutterForegroundTask.setTaskHandler(RecorderTaskHandler());
}

const _waitingInterval = Duration(seconds: 10);
const _recordingInterval = Duration(seconds: 5);

/// Runs in the service isolate: feeds GPS fixes and ticks into the pure
/// recorder machine and applies its actions to the local database.
class RecorderTaskHandler extends TaskHandler {
  late final AppDatabase _db;
  List<Place> _places = const [];
  RecorderState _state = const IdleState();
  StreamSubscription<Position>? _sub;
  Duration? _subInterval;
  Future<void> _queue = Future.value();
  String? _savedStateJson;
  double _distanceM = 0;
  int _points = 0;
  Fix? _lastUsable;
  bool _stopping = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _db = AppDatabase();
    _places = await _db.getPlaces();
    final saved = await FlutterForegroundTask.getData<String>(key: RecorderKeys.state);
    if (saved != null) {
      _state = RecorderState.fromJson((jsonDecode(saved) as Map).cast<String, Object?>());
    }
    final mode = await FlutterForegroundTask.getData<String>(key: RecorderKeys.startMode);
    await FlutterForegroundTask.removeData(key: RecorderKeys.startMode);

    final current = _state;
    if (current is RecordingState) {
      // Restarted by the system mid-trip: keep recording the same trip.
      await _db.closeInterruptedTrips(exceptId: current.tripId);
      final fixes = await _db.getFixes(current.tripId);
      _points = fixes.length;
      for (final f in fixes) {
        _addDistance(f);
      }
    } else {
      await _db.closeInterruptedTrips();
      _state = const IdleState();
      final now = DateTime.now().millisecondsSinceEpoch;
      if (mode == RecorderKeys.startNow) {
        await _handle(StartNowInput(now));
      } else if (mode == RecorderKeys.startArm) {
        await _handle(ArmInput(now));
      }
    }
    if (_state is IdleState) {
      await _shutdown();
      return;
    }
    await _sync();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _enqueue(TickInput(timestamp.millisecondsSinceEpoch));
  }

  @override
  void onReceiveData(Object data) {
    final now = DateTime.now().millisecondsSinceEpoch;
    switch (data) {
      case RecorderKeys.cmdStop:
        _enqueue(StopInput(now));
      case RecorderKeys.cmdStartNow:
        _enqueue(StartNowInput(now));
      case RecorderKeys.cmdPlacesChanged:
        _queue = _queue.then((_) async => _places = await _db.getPlaces());
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == RecorderKeys.btnStop) _enqueue(StopInput(DateTime.now().millisecondsSinceEpoch));
  }

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp('/');

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _sub?.cancel();
    _sub = null;
    await _queue;
    await _db.close();
  }

  // ----------------------------------------------------------------

  void _enqueue(RecorderInput input) {
    _queue = _queue.then((_) => _handle(input)).catchError((Object e, StackTrace st) {
      // Keep the queue alive; errors are rare (database busy) and the next
      // fix retries naturally.
    });
  }

  Future<void> _handle(RecorderInput input) async {
    if (_stopping) return;
    final before = _state;
    final step = stepRecorder(_state, input, _places);
    String? event;
    for (final action in step.actions) {
      switch (action) {
        case StartTripAction():
          await _db.startTrip(
            id: action.tripId,
            startedAt: action.startedAt,
            startReason: action.reason,
            originKind: action.origin?.id,
          );
          _distanceM = 0;
          _points = 0;
          _lastUsable = null;
          if (action.initialFixes.isNotEmpty) {
            await _db.addFixes(action.tripId, action.initialFixes);
            for (final f in action.initialFixes) {
              _addDistance(f);
            }
            _points += action.initialFixes.length;
          }
        case AppendFixAction():
          await _db.addFixes(action.tripId, [action.fix]);
          _addDistance(action.fix);
          _points++;
        case EndTripAction():
          final kept = await _db.finishTrip(action.tripId, action.endedAt, action.reason);
          event = kept
              ? 'Đã lưu chuyến đi (${(_distanceM / 1000).toStringAsFixed(1)} km).'
              : 'Chuyến quá ngắn, không lưu.';
        case CancelWaitingAction():
          event = action.reason == 'timeout' ? 'Đã hủy chờ: quá 60 phút chưa đi.' : 'Đã hủy chờ.';
      }
    }
    _state = step.state;
    if (_state is IdleState) {
      await _publish(event);
      await _shutdown();
      return;
    }
    if (_state.runtimeType != before.runtimeType || (input is TickInput && _state is RecordingState)) {
      await _sync();
    } else {
      await _saveState();
      if (input is FixInput) await _publish(null);
    }
  }

  void _addDistance(Fix f) {
    if (!f.isUsable) return;
    if (_lastUsable != null) _distanceM += distanceM(_lastUsable!.pos, f.pos);
    _lastUsable = f;
  }

  /// Applies the state to GPS subscription, notification, storage and UI.
  Future<void> _sync() async {
    await _saveState();
    final state = _state;
    final interval = state is RecordingState ? _recordingInterval : _waitingInterval;
    if (_sub == null || _subInterval != interval) {
      await _sub?.cancel();
      _subInterval = interval;
      _sub = Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          intervalDuration: interval,
        ),
      ).listen(
        (p) => _enqueue(FixInput(Fix(
          t: p.timestamp.millisecondsSinceEpoch,
          lat: p.latitude,
          lng: p.longitude,
          speedMps: p.speed >= 0 ? p.speed : null,
          accuracyM: p.accuracy,
          heading: p.heading >= 0 ? p.heading : null,
          altitude: p.altitude,
        ))),
        onError: (Object _) {},
      );
    }
    switch (state) {
      case WaitingState():
        final where = state.origin?.label;
        await FlutterForegroundTask.updateService(
          notificationTitle: 'Sẵn sàng',
          notificationText: where != null ? 'Sẽ tự ghi khi bạn rời $where' : 'Sẽ tự ghi khi bạn bắt đầu đi',
          notificationButtons: const [NotificationButton(id: RecorderKeys.btnStop, text: 'Hủy')],
        );
      case RecordingState():
        final mins = (DateTime.now().millisecondsSinceEpoch - state.startedAt) ~/ 60000;
        await FlutterForegroundTask.updateService(
          notificationTitle: 'Đang ghi chuyến đi',
          notificationText:
              'Đi lúc ${hhmm(state.startedAt)} · $mins phút · ${(_distanceM / 1000).toStringAsFixed(1)} km',
          notificationButtons: const [NotificationButton(id: RecorderKeys.btnStop, text: 'Dừng')],
        );
      case IdleState():
        break;
    }
    await _publish(null);
  }

  Future<void> _saveState() async {
    final json = jsonEncode(_state.toJson());
    if (json == _savedStateJson) return;
    _savedStateJson = json;
    await FlutterForegroundTask.saveData(key: RecorderKeys.state, value: json);
  }

  RecorderStatus _status(String? event) {
    final s = _state;
    return switch (s) {
      WaitingState() => RecorderStatus(
          phase: RecorderPhase.waiting, since: s.armedAt, originLabel: s.origin?.label, lastEvent: event),
      RecordingState() => RecorderStatus(
          phase: RecorderPhase.recording,
          since: s.startedAt,
          originLabel: s.origin?.label,
          distanceM: _distanceM,
          points: _points,
          lastEvent: event,
        ),
      IdleState() => RecorderStatus(lastEvent: event),
    };
  }

  Future<void> _publish(String? event) async {
    final json = jsonEncode(_status(event).toJson());
    await FlutterForegroundTask.saveData(key: RecorderKeys.status, value: json);
    FlutterForegroundTask.sendDataToMain(json);
  }

  Future<void> _shutdown() async {
    _stopping = true;
    await _sub?.cancel();
    _sub = null;
    await _saveState();
    await FlutterForegroundTask.stopService();
  }
}
