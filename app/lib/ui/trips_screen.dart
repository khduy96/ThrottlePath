import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../domain/fix.dart';
import '../domain/plans.dart';
import '../domain/trip_analysis.dart';
import '../providers.dart';
import 'format.dart';
import 'theme/app_theme.dart';
import 'widgets/charts.dart';
import 'widgets/common.dart';

List<LegResult>? legsOf(TripRow t) => t.legsJson == null
    ? null
    : [for (final j in jsonDecode(t.legsJson!) as List) LegResult.fromJson((j as Map).cast<String, Object?>())];

String planLabel(String? planId) => PlanId.fromId(planId)?.label ?? 'Không rõ plan';

const _shortWeekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

double? _totalMin(TripRow t) => t.endedAt == null ? null : (t.endedAt! - t.startedAt) / 60000;

/// Big number + unit, e.g. "24 phút".
Widget _minutes(BuildContext context, double min, TextStyle? style) {
  final v = min < 10 ? min.toStringAsFixed(1) : '${min.round()}';
  return Text.rich(
    TextSpan(children: [
      TextSpan(text: v),
      TextSpan(text: ' phút', style: context.text.titleMedium?.copyWith(color: context.cs.onSurfaceVariant)),
    ]),
    style: style?.copyWith(fontFeatures: tabular, height: 1.1),
  );
}

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chuyến đi')),
      body: trips.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          color: context.cs.error,
          title: 'Không đọc được dữ liệu',
          message: '$e',
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.two_wheeler_rounded,
              title: 'Chưa có chuyến nào',
              message: 'Bấm “Sẵn sàng” trước khi đi. Chuyến đi sẽ hiện ở đây sau khi bạn tới nơi.',
            );
          }
          final children = <Widget>[_Summary(trips: list)];
          String? day;
          for (final t in list) {
            final d = fmtDay(t.startedAt);
            if (d != day) {
              day = d;
              children.add(SectionHeader(d));
            } else {
              children.add(const SizedBox(height: Gap.md));
            }
            children.add(TripCard(trip: t));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(tripsProvider.future),
            child: ListView(padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xxl), children: children),
          );
        },
      ),
    );
  }
}

/// Bar chart of the last finished trips plus a median per plan.
class _Summary extends StatelessWidget {
  const _Summary({required this.trips});

  final List<TripRow> trips;

  @override
  Widget build(BuildContext context) {
    final done = trips.where((t) => t.endedAt != null).take(14).toList().reversed.toList();
    if (done.length < 2) return const SizedBox.shrink();
    final colors = context.colors;
    final byPlan = <PlanId, List<double>>{};
    for (final t in done) {
      final p = PlanId.fromId(t.planId);
      if (p != null) (byPlan[p] ??= []).add(_totalMin(t)!);
    }
    double median(List<double> v) {
      final s = [...v]..sort();
      return s.length.isOdd ? s[s.length ~/ 2] : (s[s.length ~/ 2 - 1] + s[s.length ~/ 2]) / 2;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${done.length} chuyến gần nhất', style: context.text.titleMedium),
            Text(
              'Số phút mỗi chuyến, màu theo plan',
              style: context.text.bodySmall?.copyWith(color: context.cs.onSurfaceVariant),
            ),
            const SizedBox(height: Gap.xl),
            MinutesChart(
              bars: [
                for (final t in done)
                  ChartBar(
                    label: _shortWeekdays[DateTime.fromMillisecondsSinceEpoch(t.startedAt).weekday - 1],
                    value: _totalMin(t)!,
                    color: colors.plan(PlanId.fromId(t.planId)),
                  ),
              ],
            ),
            if (byPlan.isNotEmpty) ...[
              const SizedBox(height: Gap.lg),
              const Divider(),
              const SizedBox(height: Gap.md),
              Wrap(
                spacing: Gap.xl,
                runSpacing: Gap.sm,
                children: [
                  for (final p in PlanId.values)
                    if (byPlan[p] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PlanChip(p),
                          const SizedBox(height: Gap.xs),
                          Text(
                            '${median(byPlan[p]!).round()} phút · ${byPlan[p]!.length} chuyến',
                            style: context.text.labelLarge?.copyWith(fontFeatures: tabular),
                          ),
                        ],
                      ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Glanceable card for one trip; opens the detail screen.
class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip});

  final TripRow trip;

  @override
  Widget build(BuildContext context) {
    final end = trip.endedAt;
    final total = _totalMin(trip);
    final legs = legsOf(trip);
    final plan = PlanId.fromId(trip.planId);
    final planColor = context.colors.plan(plan);
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TripDetailScreen(tripId: trip.id))),
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  PlanChip(plan),
                  const Spacer(),
                  Text(
                    '${fmtTime(trip.startedAt)} → ${end == null ? '…' : fmtTime(end)}',
                    style: context.text.labelLarge?.copyWith(color: context.cs.onSurfaceVariant, fontFeatures: tabular),
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: total == null
                        ? Row(
                            children: [
                              PulsingDot(color: context.colors.recording, size: 8),
                              Text('Đang ghi', style: context.text.headlineSmall),
                            ],
                          )
                        : _minutes(context, total, context.text.headlineLarge),
                  ),
                  if (trip.distanceM != null)
                    Text(
                      fmtKm(trip.distanceM!),
                      style: context.text.titleMedium?.copyWith(color: context.cs.onSurfaceVariant, fontFeatures: tabular),
                    ),
                ],
              ),
              if (legs != null && legs.length > 1) ...[
                const SizedBox(height: Gap.md),
                LegBar(legs: legs, color: planColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

typedef _Detail = ({TripRow? trip, TripStats? stats, List<Fix> fixes});

final _tripDetailProvider = FutureProvider.autoDispose.family<_Detail, String>((ref, id) async {
  final db = ref.watch(databaseProvider);
  final trip = await db.getTrip(id);
  if (trip == null) return (trip: null, stats: null, fixes: const <Fix>[]);
  final fixes = await db.getFixes(id);
  final end = trip.endedAt ?? (fixes.isEmpty ? trip.startedAt : fixes.last.t);
  return (trip: trip, stats: tripStats(fixes, trip.startedAt, end), fixes: fixes);
});

const _endReasons = {
  'arrived': 'tới nơi',
  'long_stop': 'dừng lâu ở điểm giữa',
  'manual': 'bấm dừng',
  'max_duration': 'quá 3 giờ',
  'interrupted': 'bị ngắt (app bị tắt)',
};

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripId});

  final String tripId;

  Future<void> _setPlan(WidgetRef ref, String? planId) async {
    await ref.read(databaseProvider).setTripPlan(tripId, planId);
    ref.invalidate(_tripDetailProvider(tripId));
    ref.invalidate(tripsProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: Icon(Icons.delete_outline_rounded, color: c.cs.error),
        title: const Text('Xóa chuyến này?'),
        content: const Text('Toàn bộ điểm GPS của chuyến sẽ bị xóa, không khôi phục được.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.cs.error,
              foregroundColor: c.cs.onError,
              minimumSize: const Size(88, 48),
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).deleteTrip(tripId);
    ref.invalidate(tripsProvider);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_tripDetailProvider(tripId));
    final places = ref.watch(placesProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết chuyến'),
        actions: [
          IconButton(
            tooltip: 'Xóa chuyến',
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          color: context.cs.error,
          title: 'Không đọc được chuyến',
          message: '$e',
        ),
        data: (d) {
          final trip = d.trip, stats = d.stats;
          if (trip == null || stats == null) {
            return const EmptyState(icon: Icons.search_off_rounded, title: 'Không tìm thấy chuyến');
          }
          final legs = legsOf(trip);
          final end = trip.endedAt;
          final plan = PlanId.fromId(trip.planId);
          final total = _totalMin(trip);
          return ListView(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xxl),
            children: [
              Row(
                children: [
                  PlanChip(plan),
                  const SizedBox(width: Gap.sm),
                  Text(
                    fmtDay(trip.startedAt),
                    style: context.text.labelLarge?.copyWith(color: context.cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              if (total != null)
                _minutes(context, total, context.text.displayMedium)
              else
                Text('Đang ghi', style: context.text.displaySmall),
              const SizedBox(height: Gap.xs),
              Text(
                'Đi ${fmtTime(trip.startedAt)} → ${end == null ? 'đang ghi' : 'tới ${fmtTime(end)}'}',
                style: context.text.titleMedium?.copyWith(color: context.cs.onSurfaceVariant, fontFeatures: tabular),
              ),
              const SizedBox(height: Gap.md),
              Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  _InfoChip(
                    icon: trip.startReason == 'auto' ? Icons.auto_mode_rounded : Icons.touch_app_rounded,
                    text: trip.startReason == 'auto' ? 'Tự ghi khi rời đi' : 'Bấm ghi ngay',
                  ),
                  if (trip.endReason != null)
                    _InfoChip(
                      icon: trip.endReason == 'interrupted' ? Icons.warning_amber_rounded : Icons.flag_rounded,
                      text: 'Kết thúc: ${_endReasons[trip.endReason] ?? trip.endReason}',
                      color: trip.endReason == 'interrupted' ? context.colors.warning : null,
                    ),
                ],
              ),
              const SectionHeader('Tuyến đã đi'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Gap.md),
                  child: TraceView(fixes: d.fixes, places: places),
                ),
              ),
              const SectionHeader('Từng đoạn'),
              if (legs == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Gap.lg),
                    child: Row(
                      children: [
                        IconBadge(Icons.call_split_rounded, color: context.colors.idle),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: Text(
                            'Chưa chia được đoạn (không nhận ra plan, hoặc không ghé điểm giữa).',
                            style: context.text.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Gap.lg),
                    child: _LegTimeline(legs: legs, color: context.colors.plan(plan)),
                  ),
                ),
              const SectionHeader('Số liệu GPS'),
              TwoColumnGrid(
                children: [
                  MetricTile(
                    icon: Icons.straighten_rounded,
                    label: 'Quãng đường',
                    value: (stats.distanceM / 1000).toStringAsFixed(1),
                    unit: 'km',
                  ),
                  MetricTile(
                    icon: Icons.speed_rounded,
                    label: 'Tốc độ TB',
                    value: stats.avgSpeedKmh.toStringAsFixed(1),
                    unit: 'km/h',
                    color: speedColor(stats.avgSpeedKmh),
                  ),
                  if (stats.maxSpeedKmh != null)
                    MetricTile(
                      icon: Icons.bolt_rounded,
                      label: 'Cao nhất',
                      value: stats.maxSpeedKmh!.toStringAsFixed(0),
                      unit: 'km/h',
                    ),
                  MetricTile(
                    icon: Icons.scatter_plot_rounded,
                    label: 'Điểm GPS',
                    value: '${stats.pointCount}',
                  ),
                  if (stats.avgAccuracyM != null)
                    MetricTile(
                      icon: Icons.gps_fixed_rounded,
                      label: 'Sai số TB',
                      value: '${stats.avgAccuracyM!.round()}',
                      unit: 'm',
                    ),
                ],
              ),
              const SectionHeader('Plan của chuyến'),
              DropdownButtonFormField<String?>(
                initialValue: trip.planManual ? trip.planId : null,
                borderRadius: BorderRadius.circular(Radii.sm),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text('Tự nhận (${planLabel(trip.planManual ? null : trip.planId)})'),
                  ),
                  for (final p in PlanId.values) DropdownMenuItem(value: p.id, child: Text(p.label)),
                ],
                onChanged: (v) => _setPlan(ref, v),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(text, style: context.text.labelMedium?.copyWith(color: c)),
        ],
      ),
    );
  }
}

/// Vertical timeline: place nodes joined by riding segments.
class _LegTimeline extends StatelessWidget {
  const _LegTimeline({required this.legs, required this.color});

  final List<LegResult> legs;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    Widget node(LegResult l, {required bool first}) {
      final kind = first ? l.from : l.to;
      final t = first ? l.startT : l.endT;
      return Row(
        children: [
          IconBadge(placeIcon(kind), color: color, size: 40),
          const SizedBox(width: Gap.md),
          Expanded(child: Text(kind.label, style: context.text.titleMedium)),
          Text(
            fmtTime(t),
            style: context.text.labelLarge?.copyWith(color: context.cs.onSurfaceVariant, fontFeatures: tabular),
          ),
        ],
      );
    }

    rows.add(node(legs.first, first: true));
    for (final l in legs) {
      rows.add(IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Center(
                child: Container(
                  width: 3,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
            const SizedBox(width: Gap.md),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.md),
              child: Row(
                children: [
                  Icon(Icons.two_wheeler_rounded, size: 18, color: color),
                  const SizedBox(width: Gap.sm),
                  Text(
                    fmtMin(l.actualMin),
                    style: context.text.titleLarge?.copyWith(color: color, fontFeatures: tabular),
                  ),
                  if (l.stopMin != null) ...[
                    const SizedBox(width: Gap.md),
                    Text(
                      '+ dừng ${fmtMin(l.stopMin!)}',
                      style: context.text.labelMedium?.copyWith(color: context.cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ));
      rows.add(node(l, first: false));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}
