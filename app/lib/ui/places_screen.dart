import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/geo.dart';
import '../domain/parse_lat_lng.dart';
import '../domain/place.dart';
import '../providers.dart';
import '../recorder/recorder_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

Color placeColor(BuildContext context, PlaceKind k) => switch (k) {
      PlaceKind.home => context.colors.morning,
      PlaceKind.stop => context.colors.evening2,
      PlaceKind.work => context.colors.evening1,
    };

class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(placesProvider).value ?? const <Place>[];
    final byKind = {for (final p in places) p.kind: p};
    final done = PlaceKind.values.where(byKind.containsKey).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Địa điểm')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xxl),
        children: [
          ProgressHeader(
            done: done,
            total: PlaceKind.values.length,
            title: done == PlaceKind.values.length ? 'Đã nhập đủ địa điểm' : 'Nhập $done/${PlaceKind.values.length} địa điểm',
          ),
          const SizedBox(height: Gap.lg),
          for (final kind in [PlaceKind.home, PlaceKind.stop, PlaceKind.work]) ...[
            _PlaceCard(kind: kind, place: byKind[kind]),
            const SizedBox(height: Gap.md),
          ],
          const SizedBox(height: Gap.sm),
          const InfoNote(
            'Bán kính là vùng quanh địa điểm được tính là “đang ở đó”. Rời khỏi vùng này = bắt đầu chuyến; '
            'vào vùng của đích và ở lại 60 giây = kết thúc chuyến.',
          ),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.kind, required this.place});

  final PlaceKind kind;
  final Place? place;

  @override
  Widget build(BuildContext context) {
    final c = placeColor(context, kind);
    final p = place;
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => PlaceEditScreen(kind: kind, existing: p),
        )),
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Row(
            children: [
              IconBadge(placeIcon(kind), color: c, size: 52),
              const SizedBox(width: Gap.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p?.name ?? kind.label, style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    if (p == null)
                      Text('Chưa nhập — chạm để thêm', style: context.text.bodyMedium?.copyWith(color: context.colors.warning))
                    else ...[
                      Text(
                        '${p.pos.lat.toStringAsFixed(5)}, ${p.pos.lng.toStringAsFixed(5)}',
                        style: context.text.bodySmall?.copyWith(color: context.cs.onSurfaceVariant, fontFeatures: tabular),
                      ),
                      Text(
                        'Bán kính ${p.radiusM} m',
                        style: context.text.bodySmall?.copyWith(color: context.cs.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                p == null ? Icons.add_circle_rounded : Icons.check_circle_rounded,
                color: p == null ? context.cs.primary : context.colors.success,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceEditScreen extends ConsumerStatefulWidget {
  const PlaceEditScreen({super.key, required this.kind, this.existing});

  final PlaceKind kind;
  final Place? existing;

  @override
  ConsumerState<PlaceEditScreen> createState() => _PlaceEditScreenState();
}

class _PlaceEditScreenState extends ConsumerState<PlaceEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _coords;
  late final TextEditingController _radius;
  String? _error;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? widget.kind.label);
    _coords = TextEditingController(text: e?.pos.toString() ?? '');
    _radius = TextEditingController(text: '${e?.radiusM ?? Place.defaultRadiusM}');
  }

  @override
  void dispose() {
    _name.dispose();
    _coords.dispose();
    _radius.dispose();
    super.dispose();
  }

  Future<void> _useCurrent() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    final err = await ensureRecordingPermissions();
    if (err != null) {
      if (mounted) {
        setState(() {
          _locating = false;
          _error = err;
        });
      }
      return;
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 30)),
      );
      if (!mounted) return;
      setState(() {
        _coords.text = LatLng(p.latitude, p.longitude).toString();
        _error = p.accuracy > 30 ? 'Sai số GPS ${p.accuracy.round()} m — nên đứng ngoài trời rồi lấy lại.' : null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Không lấy được vị trí: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    final parsed = parseLatLng(_coords.text);
    final radius = int.tryParse(_radius.text.trim());
    if (parsed.value == null) {
      setState(() => _error = parsed.error);
      return;
    }
    if (radius == null || radius < 30 || radius > 500) {
      setState(() => _error = 'Bán kính phải từ 30 đến 500 m.');
      return;
    }
    final name = _name.text.trim().isEmpty ? widget.kind.label : _name.text.trim();
    await ref.read(databaseProvider).upsertPlace(Place(kind: widget.kind, name: name, pos: parsed.value!, radiusM: radius));
    await _notifyRecorder();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(databaseProvider).deletePlace(widget.kind);
    await _notifyRecorder();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _notifyRecorder() async {
    if (await FlutterForegroundTask.isRunningService) {
      ref.read(recorderProvider.notifier).notifyPlacesChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kind.label),
        actions: [
          if (widget.existing != null)
            IconButton(tooltip: 'Xóa', onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xxl),
        children: [
          Center(child: IconBadge(placeIcon(widget.kind), color: placeColor(context, widget.kind), size: 72)),
          const SizedBox(height: Gap.xl),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Tên', prefixIcon: Icon(Icons.label_outline_rounded)),
          ),
          const SizedBox(height: Gap.lg),
          TextField(
            controller: _coords,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Tọa độ hoặc link Google Maps',
              hintText: '10.7769, 106.7009',
              prefixIcon: Icon(Icons.pin_drop_outlined),
            ),
          ),
          const SizedBox(height: Gap.sm),
          OutlinedButton.icon(
            onPressed: _locating ? null : _useCurrent,
            icon: _locating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location_rounded),
            label: const Text('Dùng vị trí hiện tại (khi đang đứng ở đây)'),
          ),
          const SizedBox(height: Gap.lg),
          TextField(
            controller: _radius,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Bán kính',
              suffixText: 'm',
              helperText: 'Từ 30 đến 500 m. Mặc định 100 m.',
              prefixIcon: Icon(Icons.radar_rounded),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: Gap.md),
            Container(
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                color: context.cs.errorContainer,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: context.cs.onErrorContainer),
                  const SizedBox(width: Gap.sm),
                  Expanded(child: Text(_error!, style: TextStyle(color: context.cs.onErrorContainer))),
                ],
              ),
            ),
          ],
          const SizedBox(height: Gap.xl),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check_rounded), label: const Text('Lưu')),
        ],
      ),
    );
  }
}
