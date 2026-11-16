import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/fix.dart';
import '../domain/geo.dart';
import '../domain/place.dart' as domain;
import '../domain/plans.dart';
import '../domain/trip_analysis.dart';

part 'database.g.dart';

const dbName = 'throttle_path';

@DataClassName('PlaceRow')
class Places extends Table {
  TextColumn get kind => text()();
  TextColumn get name => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  IntColumn get radiusM => integer().withDefault(const Constant(domain.Place.defaultRadiusM))();

  @override
  Set<Column> get primaryKey => {kind};
}

@DataClassName('TripRow')
class LocalTrips extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text().nullable()();

  /// Set by the user from the Trips screen; overrides plan detection.
  BoolColumn get planManual => boolean().withDefault(const Constant(false))();
  TextColumn get originKind => text().nullable()();
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer().nullable()();

  /// 'auto' | 'manual'
  TextColumn get startReason => text()();

  /// 'arrived' | 'long_stop' | 'manual' | 'max_duration' | 'interrupted'
  TextColumn get endReason => text().nullable()();
  RealColumn get distanceM => real().nullable()();
  IntColumn get pointCount => integer().nullable()();

  /// JSON list of LegResult, null when legs could not be split.
  TextColumn get legsJson => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PointRow')
@TableIndex(name: 'trace_points_trip', columns: {#tripId, #t})
class TracePoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tripId => text().references(LocalTrips, #id, onDelete: KeyAction.cascade)();
  IntColumn get t => integer()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get speedMps => real().nullable()();
  RealColumn get accuracyM => real().nullable()();
  RealColumn get heading => real().nullable()();
  RealColumn get altitude => real().nullable()();
}

/// Local store. The UI isolate and the recorder isolate each open their own
/// connection on the same file (WAL mode).
@DriftDatabase(tables: [Places, LocalTrips, TracePoints])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: dbName));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA journal_mode=WAL');
          await customStatement('PRAGMA busy_timeout=5000');
          await customStatement('PRAGMA foreign_keys=ON');
        },
      );

  // ------------------------------------------------------------ places

  Future<List<domain.Place>> getPlaces() async => (await select(places).get()).map(_toPlace).toList();

  Stream<List<domain.Place>> watchPlaces() => select(places).watch().map((rows) => rows.map(_toPlace).toList());

  Future<void> upsertPlace(domain.Place p) => into(places).insertOnConflictUpdate(PlacesCompanion.insert(
        kind: p.kind.id,
        name: p.name,
        lat: p.pos.lat,
        lng: p.pos.lng,
        radiusM: Value(p.radiusM),
      ));

  Future<void> deletePlace(domain.PlaceKind kind) => (delete(places)..where((t) => t.kind.equals(kind.id))).go();

  static domain.Place _toPlace(PlaceRow r) => domain.Place(
        kind: domain.PlaceKind.fromId(r.kind)!,
        name: r.name,
        pos: LatLng(r.lat, r.lng),
        radiusM: r.radiusM,
      );

  // ------------------------------------------------------------ trips

  Future<void> startTrip({
    required String id,
    required int startedAt,
    required String startReason,
    String? originKind,
  }) =>
      into(localTrips).insertOnConflictUpdate(LocalTripsCompanion.insert(
        id: id,
        startedAt: startedAt,
        startReason: startReason,
        originKind: Value(originKind),
      ));

  Future<void> addFixes(String tripId, List<Fix> fixes) => batch((b) {
        b.insertAll(tracePoints, [
          for (final f in fixes)
            TracePointsCompanion.insert(
              tripId: tripId,
              t: f.t,
              lat: f.lat,
              lng: f.lng,
              speedMps: Value(f.speedMps),
              accuracyM: Value(f.accuracyM),
              heading: Value(f.heading),
              altitude: Value(f.altitude),
            ),
        ]);
      });

  Future<List<Fix>> getFixes(String tripId) async {
    final rows = await (select(tracePoints)
          ..where((p) => p.tripId.equals(tripId))
          ..orderBy([(p) => OrderingTerm.asc(p.t)]))
        .get();
    return [
      for (final r in rows)
        Fix(
          t: r.t,
          lat: r.lat,
          lng: r.lng,
          speedMps: r.speedMps,
          accuracyM: r.accuracyM,
          heading: r.heading,
          altitude: r.altitude,
        ),
    ];
  }

  Future<TripRow?> getTrip(String id) => (select(localTrips)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<TripRow>> getTrips() =>
      (select(localTrips)..orderBy([(t) => OrderingTerm.desc(t.startedAt)])).get();

  Future<void> deleteTrip(String id) => transaction(() async {
        await (delete(tracePoints)..where((p) => p.tripId.equals(id))).go();
        await (delete(localTrips)..where((t) => t.id.equals(id))).go();
      });

  /// Closes a trip and stores its summary; drops it when too short.
  /// Returns false when the trip was dropped.
  Future<bool> finishTrip(String id, int endedAt, String endReason) async {
    final trip = await getTrip(id);
    if (trip == null) return false;
    final fixes = await getFixes(id);
    if (isTooShort(fixes, trip.startedAt, endedAt)) {
      await deleteTrip(id);
      return false;
    }
    await (update(localTrips)..where((t) => t.id.equals(id))).write(LocalTripsCompanion(
      endedAt: Value(endedAt),
      endReason: Value(endReason),
      pointCount: Value(fixes.length),
      distanceM: Value(traceDistanceM(fixes)),
    ));
    await analyzeTrip(id);
    return true;
  }

  /// (Re)computes plan and legs of a finished trip.
  Future<void> analyzeTrip(String id) async {
    final trip = await getTrip(id);
    if (trip == null || trip.endedAt == null) return;
    final fixes = await getFixes(id);
    final placeList = await getPlaces();
    final planId = trip.planManual ? trip.planId : detectPlan(fixes, placeList)?.plan.id;
    String? legsJson;
    final plan = PlanId.fromId(planId);
    if (plan != null) {
      final legs = splitTraceByLegs(fixes, plan, placeList, trip.startedAt, trip.endedAt!);
      if (legs != null) legsJson = jsonEncode([for (final l in legs) l.toJson()]);
    }
    await (update(localTrips)..where((t) => t.id.equals(id))).write(LocalTripsCompanion(
      planId: Value(planId),
      legsJson: Value(legsJson),
    ));
  }

  Future<void> setTripPlan(String id, String? planId) async {
    await (update(localTrips)..where((t) => t.id.equals(id))).write(LocalTripsCompanion(
      planId: Value(planId),
      planManual: Value(planId != null),
    ));
    await analyzeTrip(id);
  }

  /// Trips left open by a killed recorder: close them at their last point.
  Future<void> closeInterruptedTrips({String? exceptId}) async {
    final open = await (select(localTrips)..where((t) => t.endedAt.isNull())).get();
    for (final t in open) {
      if (t.id == exceptId) continue;
      final last = await (selectOnly(tracePoints)
            ..addColumns([tracePoints.t.max()])
            ..where(tracePoints.tripId.equals(t.id)))
          .map((r) => r.read(tracePoints.t.max()))
          .getSingleOrNull();
      await finishTrip(t.id, last ?? t.startedAt, 'interrupted');
    }
  }

  Future<int> countPoints() async {
    final c = tracePoints.id.count();
    return (selectOnly(tracePoints)..addColumns([c])).map((r) => r.read(c) ?? 0).getSingle();
  }
}
