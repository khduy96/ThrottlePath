import 'geo.dart';

enum PlaceKind {
  home('home', 'Nhà'),
  work('work', 'Công ty'),
  stop('stop', 'Cửa Hàng');

  const PlaceKind(this.id, this.label);

  final String id;
  final String label;

  static PlaceKind? fromId(String? id) {
    for (final k in values) {
      if (k.id == id) return k;
    }
    return null;
  }
}

class Place {
  const Place({
    required this.kind,
    required this.name,
    required this.pos,
    this.radiusM = defaultRadiusM,
  });

  static const int defaultRadiusM = 100;

  final PlaceKind kind;
  final String name;
  final LatLng pos;
  final int radiusM;

  bool contains(LatLng p) => distanceM(pos, p) <= radiusM;

  Map<String, Object?> toJson() =>
      {'kind': kind.id, 'name': name, 'lat': pos.lat, 'lng': pos.lng, 'radius_m': radiusM};

  static Place fromJson(Map<String, Object?> j) => Place(
        kind: PlaceKind.fromId(j['kind'] as String)!,
        name: j['name'] as String,
        pos: LatLng((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble()),
        radiusM: (j['radius_m'] as num).toInt(),
      );
}

/// The place whose radius contains [p]; the nearest one when radii overlap.
Place? placeContaining(LatLng p, Iterable<Place> places) {
  Place? best;
  var bestD = double.infinity;
  for (final place in places) {
    final d = distanceM(place.pos, p);
    if (d <= place.radiusM && d < bestD) {
      best = place;
      bestD = d;
    }
  }
  return best;
}
