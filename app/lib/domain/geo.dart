import 'dart:math' as math;

/// A WGS84 coordinate.
class LatLng {
  const LatLng(this.lat, this.lng);

  final double lat;
  final double lng;

  bool get isValid =>
      lat.isFinite && lng.isFinite && lat.abs() <= 90 && lng.abs() <= 180;

  @override
  bool operator ==(Object other) =>
      other is LatLng && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
}

const double _earthRadiusM = 6371008.8;

double _rad(double deg) => deg * math.pi / 180;

/// Great-circle distance in metres.
double distanceM(LatLng a, LatLng b) {
  final dLat = _rad(b.lat - a.lat);
  final dLng = _rad(b.lng - a.lng);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(a.lat)) * math.cos(_rad(b.lat)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusM * math.asin(math.min(1.0, math.sqrt(h)));
}
