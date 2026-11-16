import 'dart:async';
import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../providers.dart';
import 'protocol.dart';
import 'recorder_task.dart';

const _serviceId = 4100;

/// Must run in main() before runApp.
void initForegroundTask() {
  FlutterForegroundTask.initCommunicationPort();
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'trip_recorder',
      channelName: 'Ghi chuyến đi',
      channelDescription: 'Thông báo khi app đang chờ đi hoặc đang ghi chuyến đi',
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(30000),
      allowWakeLock: true,
      allowAutoRestart: true,
    ),
  );
}

/// Checks GPS and permissions. Returns a Vietnamese error, or null when ready.
Future<String?> ensureRecordingPermissions() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    return 'GPS (Vị trí) đang tắt. Bật Vị trí trong cài đặt điện thoại rồi thử lại.';
  }
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
  if (perm == LocationPermission.deniedForever) {
    return 'Quyền vị trí đã bị chặn. Vào màn "Quyền & pin" để mở cài đặt app và cấp quyền.';
  }
  if (perm == LocationPermission.denied || perm == LocationPermission.unableToDetermine) {
    return 'Cần quyền vị trí để ghi chuyến đi.';
  }
  final notif = await FlutterForegroundTask.checkNotificationPermission();
  if (notif != NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }
  return null;
}

/// UI-side handle on the recorder service.
class RecorderController extends Notifier<RecorderStatus> {
  @override
  RecorderStatus build() {
    FlutterForegroundTask.addTaskDataCallback(_onData);
    ref.onDispose(() => FlutterForegroundTask.removeTaskDataCallback(_onData));
    unawaited(refresh());
    return const RecorderStatus();
  }

  void _onData(Object data) {
    if (data is! String) return;
    final status = RecorderStatus.fromJson((jsonDecode(data) as Map).cast<String, Object?>());
    final wasRecording = state.phase == RecorderPhase.recording;
    state = status;
    if (status.lastEvent != null || (wasRecording && status.phase != RecorderPhase.recording)) {
      ref.invalidate(tripsProvider);
    }
  }

  /// Reloads the status saved by the service (app launch / resume).
  Future<void> refresh() async {
    final running = await FlutterForegroundTask.isRunningService;
    if (!running) {
      state = const RecorderStatus();
      return;
    }
    final saved = await FlutterForegroundTask.getData<String>(key: RecorderKeys.status);
    if (saved != null) {
      state = RecorderStatus.fromJson((jsonDecode(saved) as Map).cast<String, Object?>()).copyWith();
    }
  }

  void clearEvent() => state = state.copyWith();

  /// "Sẵn sàng". Returns an error message or null.
  Future<String?> arm() => _start(RecorderKeys.startArm);

  /// "Ghi ngay". Returns an error message or null.
  Future<String?> startNow() async {
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask(RecorderKeys.cmdStartNow);
      return null;
    }
    return _start(RecorderKeys.startNow);
  }

  /// "Hủy" / "Dừng".
  Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask(RecorderKeys.cmdStop);
    } else {
      state = const RecorderStatus();
    }
  }

  void notifyPlacesChanged() => FlutterForegroundTask.sendDataToTask(RecorderKeys.cmdPlacesChanged);

  Future<String?> _start(String mode) async {
    if (await FlutterForegroundTask.isRunningService) return null;
    final err = await ensureRecordingPermissions();
    if (err != null) return err;
    // A stale machine state from a killed service must not be resumed.
    await FlutterForegroundTask.removeData(key: RecorderKeys.state);
    await FlutterForegroundTask.saveData(key: RecorderKeys.startMode, value: mode);
    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: const [ForegroundServiceTypes.location],
      notificationTitle: mode == RecorderKeys.startNow ? 'Đang ghi chuyến đi' : 'Sẵn sàng',
      notificationText: 'Đang lấy vị trí…',
      notificationButtons: [
        NotificationButton(id: RecorderKeys.btnStop, text: mode == RecorderKeys.startNow ? 'Dừng' : 'Hủy'),
      ],
      callback: recorderCallback,
    );
    if (result is ServiceRequestFailure) {
      return 'Không khởi động được dịch vụ ghi: ${result.error}';
    }
    state = RecorderStatus(
      phase: mode == RecorderKeys.startNow ? RecorderPhase.recording : RecorderPhase.waiting,
      since: DateTime.now().millisecondsSinceEpoch,
    );
    return null;
  }
}
