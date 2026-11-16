import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'domain/place.dart';
import 'recorder/protocol.dart';
import 'recorder/recorder_controller.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final placesProvider = StreamProvider<List<Place>>((ref) => ref.watch(databaseProvider).watchPlaces());

/// Trips are written by the recorder isolate, so this is invalidated on
/// recorder events instead of watching the table.
final tripsProvider = FutureProvider<List<TripRow>>((ref) => ref.watch(databaseProvider).getTrips());

final recorderProvider = NotifierProvider<RecorderController, RecorderStatus>(RecorderController.new);
