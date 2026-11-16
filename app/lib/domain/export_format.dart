import 'dart:convert';

import 'fix.dart';

/// A trip with its raw points, as exported.
class ExportTrip {
  const ExportTrip({
    required this.id,
    required this.planId,
    required this.startedAt,
    required this.endedAt,
    required this.startReason,
    required this.endReason,
    required this.fixes,
    this.legs,
  });

  final String id;
  final String? planId;
  final int startedAt;
  final int? endedAt;
  final String startReason;
  final String? endReason;
  final List<Fix> fixes;
  final List<Map<String, Object?>>? legs;
}

String _iso(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

String _xml(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

/// GPX 1.1, one track per trip. Speed and accuracy go into `extensions`.
String buildGpx(List<ExportTrip> trips) {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<gpx version="1.1" creator="throttle_path" xmlns="http://www.topografix.com/GPX/1/1">');
  for (final t in trips) {
    b
      ..writeln('  <trk>')
      ..writeln('    <name>${_xml('${t.planId ?? 'trip'} ${_iso(t.startedAt)}')}</name>')
      ..writeln('    <trkseg>');
    for (final f in t.fixes) {
      b.write('      <trkpt lat="${f.lat}" lon="${f.lng}">');
      if (f.altitude != null) b.write('<ele>${f.altitude}</ele>');
      b.write('<time>${_iso(f.t)}</time>');
      if (f.speedMps != null || f.accuracyM != null) {
        b.write('<extensions>');
        if (f.speedMps != null) b.write('<speed>${f.speedMps}</speed>');
        if (f.accuracyM != null) b.write('<accuracy>${f.accuracyM}</accuracy>');
        b.write('</extensions>');
      }
      b.writeln('</trkpt>');
    }
    b
      ..writeln('    </trkseg>')
      ..writeln('  </trk>');
  }
  b.writeln('</gpx>');
  return b.toString();
}

String buildJson(List<ExportTrip> trips, {required Map<String, Object?> meta}) {
  return const JsonEncoder.withIndent(' ').convert({
    'meta': meta,
    'trips': [
      for (final t in trips)
        {
          'id': t.id,
          'plan_id': t.planId,
          'started_at': t.startedAt,
          'ended_at': t.endedAt,
          'start_reason': t.startReason,
          'end_reason': t.endReason,
          'legs': t.legs,
          'points': [for (final f in t.fixes) f.toJson()],
        }
    ],
  });
}
