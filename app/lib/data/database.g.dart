// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PlacesTable extends Places with TableInfo<$PlacesTable, PlaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _radiusMMeta = const VerificationMeta(
    'radiusM',
  );
  @override
  late final GeneratedColumn<int> radiusM = GeneratedColumn<int>(
    'radius_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(domain.Place.defaultRadiusM),
  );
  @override
  List<GeneratedColumn> get $columns => [kind, name, lat, lng, radiusM];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'places';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('radius_m')) {
      context.handle(
        _radiusMMeta,
        radiusM.isAcceptableOrUnknown(data['radius_m']!, _radiusMMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind};
  @override
  PlaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaceRow(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      radiusM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}radius_m'],
      )!,
    );
  }

  @override
  $PlacesTable createAlias(String alias) {
    return $PlacesTable(attachedDatabase, alias);
  }
}

class PlaceRow extends DataClass implements Insertable<PlaceRow> {
  final String kind;
  final String name;
  final double lat;
  final double lng;
  final int radiusM;
  const PlaceRow({
    required this.kind,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusM,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['radius_m'] = Variable<int>(radiusM);
    return map;
  }

  PlacesCompanion toCompanion(bool nullToAbsent) {
    return PlacesCompanion(
      kind: Value(kind),
      name: Value(name),
      lat: Value(lat),
      lng: Value(lng),
      radiusM: Value(radiusM),
    );
  }

  factory PlaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaceRow(
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      radiusM: serializer.fromJson<int>(json['radiusM']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'radiusM': serializer.toJson<int>(radiusM),
    };
  }

  PlaceRow copyWith({
    String? kind,
    String? name,
    double? lat,
    double? lng,
    int? radiusM,
  }) => PlaceRow(
    kind: kind ?? this.kind,
    name: name ?? this.name,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    radiusM: radiusM ?? this.radiusM,
  );
  PlaceRow copyWithCompanion(PlacesCompanion data) {
    return PlaceRow(
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      radiusM: data.radiusM.present ? data.radiusM.value : this.radiusM,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaceRow(')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('radiusM: $radiusM')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, name, lat, lng, radiusM);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaceRow &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.radiusM == this.radiusM);
}

class PlacesCompanion extends UpdateCompanion<PlaceRow> {
  final Value<String> kind;
  final Value<String> name;
  final Value<double> lat;
  final Value<double> lng;
  final Value<int> radiusM;
  final Value<int> rowid;
  const PlacesCompanion({
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.radiusM = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlacesCompanion.insert({
    required String kind,
    required String name,
    required double lat,
    required double lng,
    this.radiusM = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       name = Value(name),
       lat = Value(lat),
       lng = Value(lng);
  static Insertable<PlaceRow> custom({
    Expression<String>? kind,
    Expression<String>? name,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<int>? radiusM,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radiusM != null) 'radius_m': radiusM,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlacesCompanion copyWith({
    Value<String>? kind,
    Value<String>? name,
    Value<double>? lat,
    Value<double>? lng,
    Value<int>? radiusM,
    Value<int>? rowid,
  }) {
    return PlacesCompanion(
      kind: kind ?? this.kind,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusM: radiusM ?? this.radiusM,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (radiusM.present) {
      map['radius_m'] = Variable<int>(radiusM.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacesCompanion(')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('radiusM: $radiusM, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTripsTable extends LocalTrips
    with TableInfo<$LocalTripsTable, TripRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planManualMeta = const VerificationMeta(
    'planManual',
  );
  @override
  late final GeneratedColumn<bool> planManual = GeneratedColumn<bool>(
    'plan_manual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("plan_manual" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _originKindMeta = const VerificationMeta(
    'originKind',
  );
  @override
  late final GeneratedColumn<String> originKind = GeneratedColumn<String>(
    'origin_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startReasonMeta = const VerificationMeta(
    'startReason',
  );
  @override
  late final GeneratedColumn<String> startReason = GeneratedColumn<String>(
    'start_reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endReasonMeta = const VerificationMeta(
    'endReason',
  );
  @override
  late final GeneratedColumn<String> endReason = GeneratedColumn<String>(
    'end_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pointCountMeta = const VerificationMeta(
    'pointCount',
  );
  @override
  late final GeneratedColumn<int> pointCount = GeneratedColumn<int>(
    'point_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _legsJsonMeta = const VerificationMeta(
    'legsJson',
  );
  @override
  late final GeneratedColumn<String> legsJson = GeneratedColumn<String>(
    'legs_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    planManual,
    originKind,
    startedAt,
    endedAt,
    startReason,
    endReason,
    distanceM,
    pointCount,
    legsJson,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<TripRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    }
    if (data.containsKey('plan_manual')) {
      context.handle(
        _planManualMeta,
        planManual.isAcceptableOrUnknown(data['plan_manual']!, _planManualMeta),
      );
    }
    if (data.containsKey('origin_kind')) {
      context.handle(
        _originKindMeta,
        originKind.isAcceptableOrUnknown(data['origin_kind']!, _originKindMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('start_reason')) {
      context.handle(
        _startReasonMeta,
        startReason.isAcceptableOrUnknown(
          data['start_reason']!,
          _startReasonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startReasonMeta);
    }
    if (data.containsKey('end_reason')) {
      context.handle(
        _endReasonMeta,
        endReason.isAcceptableOrUnknown(data['end_reason']!, _endReasonMeta),
      );
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    }
    if (data.containsKey('point_count')) {
      context.handle(
        _pointCountMeta,
        pointCount.isAcceptableOrUnknown(data['point_count']!, _pointCountMeta),
      );
    }
    if (data.containsKey('legs_json')) {
      context.handle(
        _legsJsonMeta,
        legsJson.isAcceptableOrUnknown(data['legs_json']!, _legsJsonMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TripRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TripRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      ),
      planManual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}plan_manual'],
      )!,
      originKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_kind'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at'],
      ),
      startReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_reason'],
      )!,
      endReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_reason'],
      ),
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      ),
      pointCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}point_count'],
      ),
      legsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legs_json'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $LocalTripsTable createAlias(String alias) {
    return $LocalTripsTable(attachedDatabase, alias);
  }
}

class TripRow extends DataClass implements Insertable<TripRow> {
  final String id;
  final String? planId;

  /// Set by the user from the Trips screen; overrides plan detection.
  final bool planManual;
  final String? originKind;
  final int startedAt;
  final int? endedAt;

  /// 'auto' | 'manual'
  final String startReason;

  /// 'arrived' | 'long_stop' | 'manual' | 'max_duration' | 'interrupted'
  final String? endReason;
  final double? distanceM;
  final int? pointCount;

  /// JSON list of LegResult, null when legs could not be split.
  final String? legsJson;
  final bool synced;
  const TripRow({
    required this.id,
    this.planId,
    required this.planManual,
    this.originKind,
    required this.startedAt,
    this.endedAt,
    required this.startReason,
    this.endReason,
    this.distanceM,
    this.pointCount,
    this.legsJson,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || planId != null) {
      map['plan_id'] = Variable<String>(planId);
    }
    map['plan_manual'] = Variable<bool>(planManual);
    if (!nullToAbsent || originKind != null) {
      map['origin_kind'] = Variable<String>(originKind);
    }
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<int>(endedAt);
    }
    map['start_reason'] = Variable<String>(startReason);
    if (!nullToAbsent || endReason != null) {
      map['end_reason'] = Variable<String>(endReason);
    }
    if (!nullToAbsent || distanceM != null) {
      map['distance_m'] = Variable<double>(distanceM);
    }
    if (!nullToAbsent || pointCount != null) {
      map['point_count'] = Variable<int>(pointCount);
    }
    if (!nullToAbsent || legsJson != null) {
      map['legs_json'] = Variable<String>(legsJson);
    }
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  LocalTripsCompanion toCompanion(bool nullToAbsent) {
    return LocalTripsCompanion(
      id: Value(id),
      planId: planId == null && nullToAbsent
          ? const Value.absent()
          : Value(planId),
      planManual: Value(planManual),
      originKind: originKind == null && nullToAbsent
          ? const Value.absent()
          : Value(originKind),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      startReason: Value(startReason),
      endReason: endReason == null && nullToAbsent
          ? const Value.absent()
          : Value(endReason),
      distanceM: distanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceM),
      pointCount: pointCount == null && nullToAbsent
          ? const Value.absent()
          : Value(pointCount),
      legsJson: legsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(legsJson),
      synced: Value(synced),
    );
  }

  factory TripRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TripRow(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String?>(json['planId']),
      planManual: serializer.fromJson<bool>(json['planManual']),
      originKind: serializer.fromJson<String?>(json['originKind']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int?>(json['endedAt']),
      startReason: serializer.fromJson<String>(json['startReason']),
      endReason: serializer.fromJson<String?>(json['endReason']),
      distanceM: serializer.fromJson<double?>(json['distanceM']),
      pointCount: serializer.fromJson<int?>(json['pointCount']),
      legsJson: serializer.fromJson<String?>(json['legsJson']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String?>(planId),
      'planManual': serializer.toJson<bool>(planManual),
      'originKind': serializer.toJson<String?>(originKind),
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int?>(endedAt),
      'startReason': serializer.toJson<String>(startReason),
      'endReason': serializer.toJson<String?>(endReason),
      'distanceM': serializer.toJson<double?>(distanceM),
      'pointCount': serializer.toJson<int?>(pointCount),
      'legsJson': serializer.toJson<String?>(legsJson),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  TripRow copyWith({
    String? id,
    Value<String?> planId = const Value.absent(),
    bool? planManual,
    Value<String?> originKind = const Value.absent(),
    int? startedAt,
    Value<int?> endedAt = const Value.absent(),
    String? startReason,
    Value<String?> endReason = const Value.absent(),
    Value<double?> distanceM = const Value.absent(),
    Value<int?> pointCount = const Value.absent(),
    Value<String?> legsJson = const Value.absent(),
    bool? synced,
  }) => TripRow(
    id: id ?? this.id,
    planId: planId.present ? planId.value : this.planId,
    planManual: planManual ?? this.planManual,
    originKind: originKind.present ? originKind.value : this.originKind,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    startReason: startReason ?? this.startReason,
    endReason: endReason.present ? endReason.value : this.endReason,
    distanceM: distanceM.present ? distanceM.value : this.distanceM,
    pointCount: pointCount.present ? pointCount.value : this.pointCount,
    legsJson: legsJson.present ? legsJson.value : this.legsJson,
    synced: synced ?? this.synced,
  );
  TripRow copyWithCompanion(LocalTripsCompanion data) {
    return TripRow(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      planManual: data.planManual.present
          ? data.planManual.value
          : this.planManual,
      originKind: data.originKind.present
          ? data.originKind.value
          : this.originKind,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      startReason: data.startReason.present
          ? data.startReason.value
          : this.startReason,
      endReason: data.endReason.present ? data.endReason.value : this.endReason,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      pointCount: data.pointCount.present
          ? data.pointCount.value
          : this.pointCount,
      legsJson: data.legsJson.present ? data.legsJson.value : this.legsJson,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TripRow(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('planManual: $planManual, ')
          ..write('originKind: $originKind, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('startReason: $startReason, ')
          ..write('endReason: $endReason, ')
          ..write('distanceM: $distanceM, ')
          ..write('pointCount: $pointCount, ')
          ..write('legsJson: $legsJson, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    planManual,
    originKind,
    startedAt,
    endedAt,
    startReason,
    endReason,
    distanceM,
    pointCount,
    legsJson,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripRow &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.planManual == this.planManual &&
          other.originKind == this.originKind &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.startReason == this.startReason &&
          other.endReason == this.endReason &&
          other.distanceM == this.distanceM &&
          other.pointCount == this.pointCount &&
          other.legsJson == this.legsJson &&
          other.synced == this.synced);
}

class LocalTripsCompanion extends UpdateCompanion<TripRow> {
  final Value<String> id;
  final Value<String?> planId;
  final Value<bool> planManual;
  final Value<String?> originKind;
  final Value<int> startedAt;
  final Value<int?> endedAt;
  final Value<String> startReason;
  final Value<String?> endReason;
  final Value<double?> distanceM;
  final Value<int?> pointCount;
  final Value<String?> legsJson;
  final Value<bool> synced;
  final Value<int> rowid;
  const LocalTripsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.planManual = const Value.absent(),
    this.originKind = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.startReason = const Value.absent(),
    this.endReason = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.pointCount = const Value.absent(),
    this.legsJson = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTripsCompanion.insert({
    required String id,
    this.planId = const Value.absent(),
    this.planManual = const Value.absent(),
    this.originKind = const Value.absent(),
    required int startedAt,
    this.endedAt = const Value.absent(),
    required String startReason,
    this.endReason = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.pointCount = const Value.absent(),
    this.legsJson = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       startReason = Value(startReason);
  static Insertable<TripRow> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<bool>? planManual,
    Expression<String>? originKind,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<String>? startReason,
    Expression<String>? endReason,
    Expression<double>? distanceM,
    Expression<int>? pointCount,
    Expression<String>? legsJson,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (planManual != null) 'plan_manual': planManual,
      if (originKind != null) 'origin_kind': originKind,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (startReason != null) 'start_reason': startReason,
      if (endReason != null) 'end_reason': endReason,
      if (distanceM != null) 'distance_m': distanceM,
      if (pointCount != null) 'point_count': pointCount,
      if (legsJson != null) 'legs_json': legsJson,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTripsCompanion copyWith({
    Value<String>? id,
    Value<String?>? planId,
    Value<bool>? planManual,
    Value<String?>? originKind,
    Value<int>? startedAt,
    Value<int?>? endedAt,
    Value<String>? startReason,
    Value<String?>? endReason,
    Value<double?>? distanceM,
    Value<int?>? pointCount,
    Value<String?>? legsJson,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return LocalTripsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      planManual: planManual ?? this.planManual,
      originKind: originKind ?? this.originKind,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      startReason: startReason ?? this.startReason,
      endReason: endReason ?? this.endReason,
      distanceM: distanceM ?? this.distanceM,
      pointCount: pointCount ?? this.pointCount,
      legsJson: legsJson ?? this.legsJson,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (planManual.present) {
      map['plan_manual'] = Variable<bool>(planManual.value);
    }
    if (originKind.present) {
      map['origin_kind'] = Variable<String>(originKind.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (startReason.present) {
      map['start_reason'] = Variable<String>(startReason.value);
    }
    if (endReason.present) {
      map['end_reason'] = Variable<String>(endReason.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (pointCount.present) {
      map['point_count'] = Variable<int>(pointCount.value);
    }
    if (legsJson.present) {
      map['legs_json'] = Variable<String>(legsJson.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTripsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('planManual: $planManual, ')
          ..write('originKind: $originKind, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('startReason: $startReason, ')
          ..write('endReason: $endReason, ')
          ..write('distanceM: $distanceM, ')
          ..write('pointCount: $pointCount, ')
          ..write('legsJson: $legsJson, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TracePointsTable extends TracePoints
    with TableInfo<$TracePointsTable, PointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracePointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_trips (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tMeta = const VerificationMeta('t');
  @override
  late final GeneratedColumn<int> t = GeneratedColumn<int>(
    't',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMpsMeta = const VerificationMeta(
    'speedMps',
  );
  @override
  late final GeneratedColumn<double> speedMps = GeneratedColumn<double>(
    'speed_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
    'accuracy_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headingMeta = const VerificationMeta(
    'heading',
  );
  @override
  late final GeneratedColumn<double> heading = GeneratedColumn<double>(
    'heading',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _altitudeMeta = const VerificationMeta(
    'altitude',
  );
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
    'altitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    t,
    lat,
    lng,
    speedMps,
    accuracyM,
    heading,
    altitude,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trace_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<PointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('t')) {
      context.handle(_tMeta, t.isAcceptableOrUnknown(data['t']!, _tMeta));
    } else if (isInserting) {
      context.missing(_tMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('speed_mps')) {
      context.handle(
        _speedMpsMeta,
        speedMps.isAcceptableOrUnknown(data['speed_mps']!, _speedMpsMeta),
      );
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    }
    if (data.containsKey('heading')) {
      context.handle(
        _headingMeta,
        heading.isAcceptableOrUnknown(data['heading']!, _headingMeta),
      );
    }
    if (data.containsKey('altitude')) {
      context.handle(
        _altitudeMeta,
        altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PointRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      t: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}t'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      speedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_mps'],
      ),
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_m'],
      ),
      heading: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heading'],
      ),
      altitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude'],
      ),
    );
  }

  @override
  $TracePointsTable createAlias(String alias) {
    return $TracePointsTable(attachedDatabase, alias);
  }
}

class PointRow extends DataClass implements Insertable<PointRow> {
  final int id;
  final String tripId;
  final int t;
  final double lat;
  final double lng;
  final double? speedMps;
  final double? accuracyM;
  final double? heading;
  final double? altitude;
  const PointRow({
    required this.id,
    required this.tripId,
    required this.t,
    required this.lat,
    required this.lng,
    this.speedMps,
    this.accuracyM,
    this.heading,
    this.altitude,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['t'] = Variable<int>(t);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    if (!nullToAbsent || speedMps != null) {
      map['speed_mps'] = Variable<double>(speedMps);
    }
    if (!nullToAbsent || accuracyM != null) {
      map['accuracy_m'] = Variable<double>(accuracyM);
    }
    if (!nullToAbsent || heading != null) {
      map['heading'] = Variable<double>(heading);
    }
    if (!nullToAbsent || altitude != null) {
      map['altitude'] = Variable<double>(altitude);
    }
    return map;
  }

  TracePointsCompanion toCompanion(bool nullToAbsent) {
    return TracePointsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      t: Value(t),
      lat: Value(lat),
      lng: Value(lng),
      speedMps: speedMps == null && nullToAbsent
          ? const Value.absent()
          : Value(speedMps),
      accuracyM: accuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyM),
      heading: heading == null && nullToAbsent
          ? const Value.absent()
          : Value(heading),
      altitude: altitude == null && nullToAbsent
          ? const Value.absent()
          : Value(altitude),
    );
  }

  factory PointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PointRow(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      t: serializer.fromJson<int>(json['t']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      speedMps: serializer.fromJson<double?>(json['speedMps']),
      accuracyM: serializer.fromJson<double?>(json['accuracyM']),
      heading: serializer.fromJson<double?>(json['heading']),
      altitude: serializer.fromJson<double?>(json['altitude']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<String>(tripId),
      't': serializer.toJson<int>(t),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'speedMps': serializer.toJson<double?>(speedMps),
      'accuracyM': serializer.toJson<double?>(accuracyM),
      'heading': serializer.toJson<double?>(heading),
      'altitude': serializer.toJson<double?>(altitude),
    };
  }

  PointRow copyWith({
    int? id,
    String? tripId,
    int? t,
    double? lat,
    double? lng,
    Value<double?> speedMps = const Value.absent(),
    Value<double?> accuracyM = const Value.absent(),
    Value<double?> heading = const Value.absent(),
    Value<double?> altitude = const Value.absent(),
  }) => PointRow(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    t: t ?? this.t,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    speedMps: speedMps.present ? speedMps.value : this.speedMps,
    accuracyM: accuracyM.present ? accuracyM.value : this.accuracyM,
    heading: heading.present ? heading.value : this.heading,
    altitude: altitude.present ? altitude.value : this.altitude,
  );
  PointRow copyWithCompanion(TracePointsCompanion data) {
    return PointRow(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      t: data.t.present ? data.t.value : this.t,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      speedMps: data.speedMps.present ? data.speedMps.value : this.speedMps,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      heading: data.heading.present ? data.heading.value : this.heading,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PointRow(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('t: $t, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('speedMps: $speedMps, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('heading: $heading, ')
          ..write('altitude: $altitude')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    t,
    lat,
    lng,
    speedMps,
    accuracyM,
    heading,
    altitude,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PointRow &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.t == this.t &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.speedMps == this.speedMps &&
          other.accuracyM == this.accuracyM &&
          other.heading == this.heading &&
          other.altitude == this.altitude);
}

class TracePointsCompanion extends UpdateCompanion<PointRow> {
  final Value<int> id;
  final Value<String> tripId;
  final Value<int> t;
  final Value<double> lat;
  final Value<double> lng;
  final Value<double?> speedMps;
  final Value<double?> accuracyM;
  final Value<double?> heading;
  final Value<double?> altitude;
  const TracePointsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.t = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.heading = const Value.absent(),
    this.altitude = const Value.absent(),
  });
  TracePointsCompanion.insert({
    this.id = const Value.absent(),
    required String tripId,
    required int t,
    required double lat,
    required double lng,
    this.speedMps = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.heading = const Value.absent(),
    this.altitude = const Value.absent(),
  }) : tripId = Value(tripId),
       t = Value(t),
       lat = Value(lat),
       lng = Value(lng);
  static Insertable<PointRow> custom({
    Expression<int>? id,
    Expression<String>? tripId,
    Expression<int>? t,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<double>? speedMps,
    Expression<double>? accuracyM,
    Expression<double>? heading,
    Expression<double>? altitude,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (t != null) 't': t,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (speedMps != null) 'speed_mps': speedMps,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (heading != null) 'heading': heading,
      if (altitude != null) 'altitude': altitude,
    });
  }

  TracePointsCompanion copyWith({
    Value<int>? id,
    Value<String>? tripId,
    Value<int>? t,
    Value<double>? lat,
    Value<double>? lng,
    Value<double?>? speedMps,
    Value<double?>? accuracyM,
    Value<double?>? heading,
    Value<double?>? altitude,
  }) {
    return TracePointsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      t: t ?? this.t,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      speedMps: speedMps ?? this.speedMps,
      accuracyM: accuracyM ?? this.accuracyM,
      heading: heading ?? this.heading,
      altitude: altitude ?? this.altitude,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (t.present) {
      map['t'] = Variable<int>(t.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (speedMps.present) {
      map['speed_mps'] = Variable<double>(speedMps.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (heading.present) {
      map['heading'] = Variable<double>(heading.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracePointsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('t: $t, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('speedMps: $speedMps, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('heading: $heading, ')
          ..write('altitude: $altitude')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlacesTable places = $PlacesTable(this);
  late final $LocalTripsTable localTrips = $LocalTripsTable(this);
  late final $TracePointsTable tracePoints = $TracePointsTable(this);
  late final Index tracePointsTrip = Index(
    'trace_points_trip',
    'CREATE INDEX trace_points_trip ON trace_points (trip_id, t)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    places,
    localTrips,
    tracePoints,
    tracePointsTrip,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'local_trips',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('trace_points', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PlacesTableCreateCompanionBuilder =
    PlacesCompanion Function({
      required String kind,
      required String name,
      required double lat,
      required double lng,
      Value<int> radiusM,
      Value<int> rowid,
    });
typedef $$PlacesTableUpdateCompanionBuilder =
    PlacesCompanion Function({
      Value<String> kind,
      Value<String> name,
      Value<double> lat,
      Value<double> lng,
      Value<int> radiusM,
      Value<int> rowid,
    });

class $$PlacesTableFilterComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlacesTable> {
  $$PlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<int> get radiusM =>
      $composableBuilder(column: $table.radiusM, builder: (column) => column);
}

class $$PlacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlacesTable,
          PlaceRow,
          $$PlacesTableFilterComposer,
          $$PlacesTableOrderingComposer,
          $$PlacesTableAnnotationComposer,
          $$PlacesTableCreateCompanionBuilder,
          $$PlacesTableUpdateCompanionBuilder,
          (PlaceRow, BaseReferences<_$AppDatabase, $PlacesTable, PlaceRow>),
          PlaceRow,
          PrefetchHooks Function()
        > {
  $$PlacesTableTableManager(_$AppDatabase db, $PlacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<int> radiusM = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlacesCompanion(
                kind: kind,
                name: name,
                lat: lat,
                lng: lng,
                radiusM: radiusM,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String name,
                required double lat,
                required double lng,
                Value<int> radiusM = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlacesCompanion.insert(
                kind: kind,
                name: name,
                lat: lat,
                lng: lng,
                radiusM: radiusM,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlacesTable, PlaceRow>(table),
                  BaseReferences<_$AppDatabase, $PlacesTable, PlaceRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlacesTable,
      PlaceRow,
      $$PlacesTableFilterComposer,
      $$PlacesTableOrderingComposer,
      $$PlacesTableAnnotationComposer,
      $$PlacesTableCreateCompanionBuilder,
      $$PlacesTableUpdateCompanionBuilder,
      (PlaceRow, BaseReferences<_$AppDatabase, $PlacesTable, PlaceRow>),
      PlaceRow,
      PrefetchHooks Function()
    >;
typedef $$LocalTripsTableCreateCompanionBuilder =
    LocalTripsCompanion Function({
      required String id,
      Value<String?> planId,
      Value<bool> planManual,
      Value<String?> originKind,
      required int startedAt,
      Value<int?> endedAt,
      required String startReason,
      Value<String?> endReason,
      Value<double?> distanceM,
      Value<int?> pointCount,
      Value<String?> legsJson,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$LocalTripsTableUpdateCompanionBuilder =
    LocalTripsCompanion Function({
      Value<String> id,
      Value<String?> planId,
      Value<bool> planManual,
      Value<String?> originKind,
      Value<int> startedAt,
      Value<int?> endedAt,
      Value<String> startReason,
      Value<String?> endReason,
      Value<double?> distanceM,
      Value<int?> pointCount,
      Value<String?> legsJson,
      Value<bool> synced,
      Value<int> rowid,
    });

final class $$LocalTripsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalTripsTable, TripRow> {
  $$LocalTripsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TracePointsTable, List<PointRow>>
  _tracePointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.tracePoints,
    aliasName: 'local_trips__id__trace_points__trip_id',
  );

  $$TracePointsTableProcessedTableManager get tracePointsRefs {
    final manager = $$TracePointsTableTableManager(
      $_db,
      $_db.tracePoints,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tracePointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalTripsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTripsTable> {
  $$LocalTripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get planManual => $composableBuilder(
    column: $table.planManual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originKind => $composableBuilder(
    column: $table.originKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startReason => $composableBuilder(
    column: $table.startReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endReason => $composableBuilder(
    column: $table.endReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pointCount => $composableBuilder(
    column: $table.pointCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legsJson => $composableBuilder(
    column: $table.legsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tracePointsRefs(
    Expression<bool> Function($$TracePointsTableFilterComposer f) f,
  ) {
    final $$TracePointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracePoints,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracePointsTableFilterComposer(
            $db: $db,
            $table: $db.tracePoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalTripsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTripsTable> {
  $$LocalTripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get planManual => $composableBuilder(
    column: $table.planManual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originKind => $composableBuilder(
    column: $table.originKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startReason => $composableBuilder(
    column: $table.startReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endReason => $composableBuilder(
    column: $table.endReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pointCount => $composableBuilder(
    column: $table.pointCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legsJson => $composableBuilder(
    column: $table.legsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTripsTable> {
  $$LocalTripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<bool> get planManual => $composableBuilder(
    column: $table.planManual,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originKind => $composableBuilder(
    column: $table.originKind,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get startReason => $composableBuilder(
    column: $table.startReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endReason =>
      $composableBuilder(column: $table.endReason, builder: (column) => column);

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<int> get pointCount => $composableBuilder(
    column: $table.pointCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get legsJson =>
      $composableBuilder(column: $table.legsJson, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  Expression<T> tracePointsRefs<T extends Object>(
    Expression<T> Function($$TracePointsTableAnnotationComposer a) f,
  ) {
    final $$TracePointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracePoints,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracePointsTableAnnotationComposer(
            $db: $db,
            $table: $db.tracePoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalTripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTripsTable,
          TripRow,
          $$LocalTripsTableFilterComposer,
          $$LocalTripsTableOrderingComposer,
          $$LocalTripsTableAnnotationComposer,
          $$LocalTripsTableCreateCompanionBuilder,
          $$LocalTripsTableUpdateCompanionBuilder,
          (TripRow, $$LocalTripsTableReferences),
          TripRow,
          PrefetchHooks Function({bool tracePointsRefs})
        > {
  $$LocalTripsTableTableManager(_$AppDatabase db, $LocalTripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> planId = const Value.absent(),
                Value<bool> planManual = const Value.absent(),
                Value<String?> originKind = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> endedAt = const Value.absent(),
                Value<String> startReason = const Value.absent(),
                Value<String?> endReason = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                Value<int?> pointCount = const Value.absent(),
                Value<String?> legsJson = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTripsCompanion(
                id: id,
                planId: planId,
                planManual: planManual,
                originKind: originKind,
                startedAt: startedAt,
                endedAt: endedAt,
                startReason: startReason,
                endReason: endReason,
                distanceM: distanceM,
                pointCount: pointCount,
                legsJson: legsJson,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> planId = const Value.absent(),
                Value<bool> planManual = const Value.absent(),
                Value<String?> originKind = const Value.absent(),
                required int startedAt,
                Value<int?> endedAt = const Value.absent(),
                required String startReason,
                Value<String?> endReason = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                Value<int?> pointCount = const Value.absent(),
                Value<String?> legsJson = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTripsCompanion.insert(
                id: id,
                planId: planId,
                planManual: planManual,
                originKind: originKind,
                startedAt: startedAt,
                endedAt: endedAt,
                startReason: startReason,
                endReason: endReason,
                distanceM: distanceM,
                pointCount: pointCount,
                legsJson: legsJson,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalTripsTable, TripRow>(table),
                  $$LocalTripsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tracePointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tracePointsRefs) db.tracePoints],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tracePointsRefs)
                    await $_getPrefetchedDataByColumns<
                      TripRow,
                      $LocalTripsTable,
                      PointRow,
                      $TracePointsTable
                    >(
                      currentTable: table,
                      referencedTable: $$LocalTripsTableReferences
                          ._tracePointsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalTripsTableReferences(
                            db,
                            table,
                            p0,
                          ).tracePointsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'trip_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalTripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTripsTable,
      TripRow,
      $$LocalTripsTableFilterComposer,
      $$LocalTripsTableOrderingComposer,
      $$LocalTripsTableAnnotationComposer,
      $$LocalTripsTableCreateCompanionBuilder,
      $$LocalTripsTableUpdateCompanionBuilder,
      (TripRow, $$LocalTripsTableReferences),
      TripRow,
      PrefetchHooks Function({bool tracePointsRefs})
    >;
typedef $$TracePointsTableCreateCompanionBuilder =
    TracePointsCompanion Function({
      Value<int> id,
      required String tripId,
      required int t,
      required double lat,
      required double lng,
      Value<double?> speedMps,
      Value<double?> accuracyM,
      Value<double?> heading,
      Value<double?> altitude,
    });
typedef $$TracePointsTableUpdateCompanionBuilder =
    TracePointsCompanion Function({
      Value<int> id,
      Value<String> tripId,
      Value<int> t,
      Value<double> lat,
      Value<double> lng,
      Value<double?> speedMps,
      Value<double?> accuracyM,
      Value<double?> heading,
      Value<double?> altitude,
    });

final class $$TracePointsTableReferences
    extends BaseReferences<_$AppDatabase, $TracePointsTable, PointRow> {
  $$TracePointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalTripsTable _tripIdTable(_$AppDatabase db) =>
      db.localTrips.createAlias('trace_points__trip_id__local_trips__id');

  $$LocalTripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<String>('trip_id')!;

    final manager = $$LocalTripsTableTableManager(
      $_db,
      $_db.localTrips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TracePointsTableFilterComposer
    extends Composer<_$AppDatabase, $TracePointsTable> {
  $$TracePointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get t => $composableBuilder(
    column: $table.t,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalTripsTableFilterComposer get tripId {
    final $$LocalTripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.localTrips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTripsTableFilterComposer(
            $db: $db,
            $table: $db.localTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracePointsTableOrderingComposer
    extends Composer<_$AppDatabase, $TracePointsTable> {
  $$TracePointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get t => $composableBuilder(
    column: $table.t,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heading => $composableBuilder(
    column: $table.heading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalTripsTableOrderingComposer get tripId {
    final $$LocalTripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.localTrips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTripsTableOrderingComposer(
            $db: $db,
            $table: $db.localTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracePointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracePointsTable> {
  $$TracePointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get t =>
      $composableBuilder(column: $table.t, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<double> get speedMps =>
      $composableBuilder(column: $table.speedMps, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<double> get heading =>
      $composableBuilder(column: $table.heading, builder: (column) => column);

  GeneratedColumn<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => column);

  $$LocalTripsTableAnnotationComposer get tripId {
    final $$LocalTripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.localTrips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTripsTableAnnotationComposer(
            $db: $db,
            $table: $db.localTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracePointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TracePointsTable,
          PointRow,
          $$TracePointsTableFilterComposer,
          $$TracePointsTableOrderingComposer,
          $$TracePointsTableAnnotationComposer,
          $$TracePointsTableCreateCompanionBuilder,
          $$TracePointsTableUpdateCompanionBuilder,
          (PointRow, $$TracePointsTableReferences),
          PointRow,
          PrefetchHooks Function({bool tripId})
        > {
  $$TracePointsTableTableManager(_$AppDatabase db, $TracePointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracePointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracePointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracePointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<int> t = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<double?> heading = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
              }) => TracePointsCompanion(
                id: id,
                tripId: tripId,
                t: t,
                lat: lat,
                lng: lng,
                speedMps: speedMps,
                accuracyM: accuracyM,
                heading: heading,
                altitude: altitude,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String tripId,
                required int t,
                required double lat,
                required double lng,
                Value<double?> speedMps = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<double?> heading = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
              }) => TracePointsCompanion.insert(
                id: id,
                tripId: tripId,
                t: t,
                lat: lat,
                lng: lng,
                speedMps: speedMps,
                accuracyM: accuracyM,
                heading: heading,
                altitude: altitude,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TracePointsTable, PointRow>(table),
                  $$TracePointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tripId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (tripId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tripId,
                                referencedTable: $$TracePointsTableReferences
                                    ._tripIdTable(db),
                                referencedColumn: $$TracePointsTableReferences
                                    ._tripIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TracePointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TracePointsTable,
      PointRow,
      $$TracePointsTableFilterComposer,
      $$TracePointsTableOrderingComposer,
      $$TracePointsTableAnnotationComposer,
      $$TracePointsTableCreateCompanionBuilder,
      $$TracePointsTableUpdateCompanionBuilder,
      (PointRow, $$TracePointsTableReferences),
      PointRow,
      PrefetchHooks Function({bool tripId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlacesTableTableManager get places =>
      $$PlacesTableTableManager(_db, _db.places);
  $$LocalTripsTableTableManager get localTrips =>
      $$LocalTripsTableTableManager(_db, _db.localTrips);
  $$TracePointsTableTableManager get tracePoints =>
      $$TracePointsTableTableManager(_db, _db.tracePoints);
}
