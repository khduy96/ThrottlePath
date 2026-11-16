import 'package:throttle_path/domain/fix.dart';
import 'package:throttle_path/domain/geo.dart';
import 'package:throttle_path/domain/place.dart';

// Fake coordinates (not the user's real places).
const homePos = LatLng(10.7000, 106.6000);
const stopPos = LatLng(10.7200, 106.6000);
const workPos = LatLng(10.7400, 106.6000);

const places = [
  Place(kind: PlaceKind.home, name: 'Nhà', pos: homePos),
  Place(kind: PlaceKind.stop, name: 'Cửa Hàng', pos: stopPos),
  Place(kind: PlaceKind.work, name: 'Công ty', pos: workPos),
];

const t0 = 1763340000000; // fixed epoch ms

/// Metres north of [base] → LatLng (1° lat ≈ 111 km).
LatLng north(LatLng base, double m) => LatLng(base.lat + m / 111195, base.lng);

Fix fixAt(LatLng p, int t, {double acc = 5, double? speed}) =>
    Fix(t: t, lat: p.lat, lng: p.lng, accuracyM: acc, speedMps: speed);

/// Straight ride north from [from] to [to], one fix every [stepS] seconds at [speedMps].
List<Fix> ride(LatLng from, LatLng to, int startT, {double speedMps = 8, int stepS = 5}) {
  final total = distanceM(from, to);
  final fixes = <Fix>[];
  var d = 0.0;
  var t = startT;
  while (d < total) {
    fixes.add(fixAt(north(from, d), t, speed: speedMps));
    d += speedMps * stepS;
    t += stepS * 1000;
  }
  fixes.add(fixAt(to, t, speed: 0));
  return fixes;
}

/// Standing still at [p] for [seconds].
List<Fix> stay(LatLng p, int startT, int seconds, {int stepS = 5}) => [
      for (var s = 0; s <= seconds; s += stepS) fixAt(p, startT + s * 1000, speed: 0),
    ];
