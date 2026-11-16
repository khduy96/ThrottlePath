import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';
import '../domain/export_format.dart';
import '../providers.dart';
import 'format.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

final _storageProvider = FutureProvider.autoDispose<(int trips, int points, int bytes)>((ref) async {
  final db = ref.watch(databaseProvider);
  final trips = (await db.getTrips()).length;
  final points = await db.countPoints();
  final dir = await getApplicationDocumentsDirectory();
  var bytes = 0;
  for (final suffix in ['', '-wal']) {
    final f = File('${dir.path}/$dbName.sqlite$suffix');
    if (await f.exists()) bytes += await f.length();
  }
  return (trips, points, bytes);
});

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _busy = false;
  String? _result;

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final db = ref.read(databaseProvider);
      final trips = <ExportTrip>[];
      for (final t in (await db.getTrips()).reversed) {
        trips.add(ExportTrip(
          id: t.id,
          planId: t.planId,
          startedAt: t.startedAt,
          endedAt: t.endedAt,
          startReason: t.startReason,
          endReason: t.endReason,
          fixes: await db.getFixes(t.id),
        ));
      }
      final base = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/exports');
      await dir.create(recursive: true);
      final now = DateTime.now();
      final stamp = '${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}';
      final gpx = File('${dir.path}/throttle_path_$stamp.gpx');
      final json = File('${dir.path}/throttle_path_$stamp.json');
      await gpx.writeAsString(buildGpx(trips));
      await json.writeAsString(buildJson(trips, meta: {'exported_at': now.toUtc().toIso8601String(), 'version': 1}));
      final gpxSize = fmtBytes(await gpx.length());
      final jsonSize = fmtBytes(await json.length());
      if (!mounted) return;
      setState(() => _result = 'Đã lưu ${trips.length} chuyến vào:\n${dir.path}\n\n'
          'throttle_path_$stamp.gpx ($gpxSize)\n'
          'throttle_path_$stamp.json ($jsonSize)');
    } catch (e) {
      setState(() => _result = 'Lỗi khi xuất: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(_storageProvider);
    final result = _result;
    final failed = result != null && result.startsWith('Lỗi');
    final resultColor = failed ? context.cs.error : context.colors.success;
    return Scaffold(
      appBar: AppBar(title: const Text('Xuất dữ liệu')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xxl),
        children: [
          const SectionHeader('Trên máy'),
          storage.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => InfoNote('Lỗi: $e', icon: Icons.error_outline_rounded),
            data: (s) => Row(
              children: [
                Expanded(child: MetricTile(icon: Icons.route_rounded, label: 'Chuyến', value: '${s.$1}')),
                const SizedBox(width: Gap.sm),
                Expanded(child: MetricTile(icon: Icons.scatter_plot_rounded, label: 'Điểm GPS', value: '${s.$2}')),
                const SizedBox(width: Gap.sm),
                Expanded(child: MetricTile(icon: Icons.sd_storage_rounded, label: 'Dung lượng', value: fmtBytes(s.$3))),
              ],
            ),
          ),
          const SectionHeader('Xuất file'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Gap.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Format(
                    icon: Icons.map_outlined,
                    color: context.colors.evening1,
                    title: 'GPX',
                    text: 'Mở bằng Google Earth hoặc các trang xem GPS.',
                  ),
                  const SizedBox(height: Gap.md),
                  _Format(
                    icon: Icons.data_object_rounded,
                    color: context.colors.evening2,
                    title: 'JSON',
                    text: 'Đủ mọi số liệu, để sao lưu hoặc phân tích.',
                  ),
                  const SizedBox(height: Gap.lg),
                  FilledButton.icon(
                    onPressed: _busy ? null : _export,
                    icon: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.ios_share_rounded),
                    label: const Text('Xuất dữ liệu'),
                  ),
                ],
              ),
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: Gap.lg),
            Container(
              padding: const EdgeInsets.all(Gap.lg),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: resultColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(failed ? Icons.error_outline_rounded : Icons.check_circle_rounded, color: resultColor),
                  const SizedBox(width: Gap.md),
                  Expanded(child: SelectableText(result, style: context.text.bodyMedium)),
                ],
              ),
            ),
          ],
          const SizedBox(height: Gap.lg),
          const InfoNote(
            'File nằm trong thư mục riêng của app (Android/data/com.throttlepath.throttle_path/files/exports); '
            'copy ra máy tính qua cáp USB để sao lưu.',
            icon: Icons.usb_rounded,
          ),
        ],
      ),
    );
  }
}

class _Format extends StatelessWidget {
  const _Format({required this.icon, required this.color, required this.title, required this.text});

  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconBadge(icon, color: color, size: 40),
        const SizedBox(width: Gap.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleSmall),
              Text(text, style: context.text.bodySmall?.copyWith(color: context.cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
