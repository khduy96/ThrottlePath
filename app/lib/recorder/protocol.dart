/// Messages and stored keys shared by the UI isolate and the recorder task.
abstract final class RecorderKeys {
  /// Command for the task on start: [startArm] or [startNow].
  static const startMode = 'start_mode';
  static const startArm = 'arm';
  static const startNow = 'now';

  /// Machine state (JSON), so a restarted service can resume.
  static const state = 'recorder_state';

  /// Latest [RecorderStatus] (JSON), for the UI on launch.
  static const status = 'recorder_status';

  // UI → task
  static const cmdStop = 'stop';
  static const cmdStartNow = 'start_now';
  static const cmdPlacesChanged = 'places_changed';

  // Notification button ids
  static const btnStop = 'stop';
}

enum RecorderPhase { off, waiting, recording }

class RecorderStatus {
  const RecorderStatus({
    this.phase = RecorderPhase.off,
    this.since,
    this.originLabel,
    this.distanceM = 0,
    this.points = 0,
    this.lastEvent,
  });

  final RecorderPhase phase;

  /// Armed-at (waiting) or departure time (recording), epoch ms.
  final int? since;
  final String? originLabel;
  final double distanceM;
  final int points;

  /// Last finished / cancelled event, in Vietnamese, for a snackbar.
  final String? lastEvent;

  RecorderStatus copyWith({String? lastEvent}) => RecorderStatus(
        phase: phase,
        since: since,
        originLabel: originLabel,
        distanceM: distanceM,
        points: points,
        lastEvent: lastEvent,
      );

  Map<String, Object?> toJson() => {
        'phase': phase.name,
        'since': since,
        'origin': originLabel,
        'distance_m': distanceM,
        'points': points,
        'event': lastEvent,
      };

  static RecorderStatus fromJson(Map<String, Object?> j) => RecorderStatus(
        phase: RecorderPhase.values.firstWhere((p) => p.name == j['phase'], orElse: () => RecorderPhase.off),
        since: (j['since'] as num?)?.toInt(),
        originLabel: j['origin'] as String?,
        distanceM: (j['distance_m'] as num?)?.toDouble() ?? 0,
        points: (j['points'] as num?)?.toInt() ?? 0,
        lastEvent: j['event'] as String?,
      );
}

String hhmm(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
