const _weekdays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];

String two(int n) => n.toString().padLeft(2, '0');

String fmtTime(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${two(d.hour)}:${two(d.minute)}';
}

String fmtDay(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${_weekdays[d.weekday - 1]} ${two(d.day)}/${two(d.month)}';
}

String fmtMin(double min) => min < 10 ? '${min.toStringAsFixed(1)} phút' : '${min.round()} phút';

String fmtKm(double m) => '${(m / 1000).toStringAsFixed(1)} km';

String fmtBytes(int b) {
  if (b < 1024) return '$b B';
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
  return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
}
