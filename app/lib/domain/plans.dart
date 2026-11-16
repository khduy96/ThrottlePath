import 'place.dart';

/// Daily trip plans (docs/PLAN.md, schedule table). Stage A1 keeps them as
/// constants; from A2 they come from the server.
enum PlanId {
  morning('morning', 'Sáng', [PlaceKind.home, PlaceKind.stop, PlaceKind.work]),
  evening1('evening_1', 'Chiều 1', [PlaceKind.work, PlaceKind.stop]),
  evening2('evening_2', 'Chiều 2', [PlaceKind.stop, PlaceKind.home]);

  const PlanId(this.id, this.label, this.places);

  final String id;
  final String label;

  /// Ordered places: origin, intermediate stops, destination.
  final List<PlaceKind> places;

  PlaceKind get origin => places.first;
  PlaceKind get destination => places.last;
  List<PlaceKind> get intermediates => places.sublist(1, places.length - 1);

  static PlanId? fromId(String? id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// True when [place] is an intermediate stop of some plan starting at
/// [origin], so arriving there must not end the trip (morning: Cửa Hàng).
bool isIntermediateStop(PlaceKind? origin, PlaceKind place) {
  if (origin == null) return false;
  for (final plan in PlanId.values) {
    if (plan.origin == origin && plan.intermediates.contains(place)) return true;
  }
  return false;
}
