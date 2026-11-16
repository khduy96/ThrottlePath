import 'geo.dart';

/// One GPS reading. [t] is epoch milliseconds (UTC).
class Fix {
  const Fix({
    required this.t,
    required this.lat,
    required this.lng,
    this.speedMps,
    this.accuracyM,
    this.heading,
    this.altitude,
  });

  final int t;
  final double lat;
  final double lng;
  final double? speedMps;
  final double? accuracyM;
  final double? heading;
  final double? altitude;

  LatLng get pos => LatLng(lat, lng);

  /// Accurate enough to decide place entry / exit.
  bool get isUsable => accuracyM == null || accuracyM! <= maxUsableAccuracyM;

  static const double maxUsableAccuracyM = 50;

  Map<String, Object?> toJson() => {
        't': t,
        'lat': lat,
        'lng': lng,
        if (speedMps != null) 'speed': speedMps,
        if (accuracyM != null) 'acc': accuracyM,
        if (heading != null) 'heading': heading,
        if (altitude != null) 'alt': altitude,
      };

  static Fix fromJson(Map<String, Object?> j) => Fix(
        t: (j['t'] as num).toInt(),
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        speedMps: (j['speed'] as num?)?.toDouble(),
        accuracyM: (j['acc'] as num?)?.toDouble(),
        heading: (j['heading'] as num?)?.toDouble(),
        altitude: (j['alt'] as num?)?.toDouble(),
      );
}
