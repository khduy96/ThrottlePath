import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import 'theme/app_theme.dart';
import 'widgets/common.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with WidgetsBindingObserver {
  bool? _gpsOn;
  LocationPermission? _location;
  NotificationPermission? _notif;
  bool? _batteryIgnored;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final gps = await Geolocator.isLocationServiceEnabled();
    final loc = await Geolocator.checkPermission();
    final notif = await FlutterForegroundTask.checkNotificationPermission();
    final battery = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (!mounted) return;
    setState(() {
      _gpsOn = gps;
      _location = loc;
      _notif = notif;
      _batteryIgnored = battery;
    });
  }

  Future<void> _requestLocation() async {
    if (_location == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.requestPermission();
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final locOk = _location == LocationPermission.whileInUse || _location == LocationPermission.always;
    final checks = [
      _gpsOn,
      _location == null ? null : locOk,
      _notif == null ? null : _notif == NotificationPermission.granted,
      _batteryIgnored,
    ];
    final done = checks.where((c) => c == true).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Quyền & pin')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xxl),
        children: [
          ProgressHeader(
            done: done,
            total: checks.length,
            title: done == checks.length ? 'Mọi thứ đã sẵn sàng' : 'Còn ${checks.length - done} bước cần làm',
            subtitle: 'Để app ghi chuyến đi trọn vẹn, không bị tắt giữa đường.',
          ),
          const SizedBox(height: Gap.lg),
          _Step(
            index: 1,
            ok: checks[0],
            title: 'GPS (Vị trí) đang bật',
            action: 'Mở cài đặt',
            onTap: () async {
              await Geolocator.openLocationSettings();
              await _load();
            },
          ),
          _Step(
            index: 2,
            ok: checks[1],
            title: 'Quyền vị trí',
            subtitle: 'Chọn “Khi dùng ứng dụng” là đủ — app ghi qua thông báo cố định.',
            action: _location == LocationPermission.deniedForever ? 'Mở cài đặt app' : 'Cấp quyền',
            onTap: _requestLocation,
          ),
          _Step(
            index: 3,
            ok: checks[2],
            title: 'Quyền thông báo',
            subtitle: 'Để hiện thông báo “Sẵn sàng / Đang ghi” và nút Hủy / Dừng.',
            action: 'Cấp quyền',
            onTap: () async {
              await FlutterForegroundTask.requestNotificationPermission();
              await _load();
            },
          ),
          _Step(
            index: 4,
            ok: checks[3],
            title: 'Tắt tối ưu pin cho app',
            subtitle: 'Nếu không, điện thoại có thể tắt app giữa chuyến và mất dữ liệu.',
            action: 'Tắt tối ưu pin',
            onTap: () async {
              await FlutterForegroundTask.requestIgnoreBatteryOptimization();
              await _load();
            },
          ),
          const SectionHeader('Theo hãng điện thoại'),
          const InfoNote(
            'Một số hãng vẫn tắt app chạy nền dù đã tắt tối ưu pin. Chọn hãng máy của bạn và làm thêm theo hướng dẫn. '
            'Tên mục có thể khác chút tùy bản Android. Xem thêm: dontkillmyapp.com',
            icon: Icons.phone_android_rounded,
          ),
          const SizedBox(height: Gap.md),
          for (final (brand, steps) in _oemGuides) ...[
            _OemCard(brand: brand, steps: steps),
            const SizedBox(height: Gap.sm),
          ],
        ],
      ),
    );
  }
}

const _oemGuides = [
  (
    'Xiaomi / Redmi / POCO',
    [
      'Cài đặt → Ứng dụng → Throttle Path → Tiết kiệm pin → “Không giới hạn”.',
      'Bật “Tự khởi động”.',
      'Mở đa nhiệm, kéo xuống trên app để khóa (biểu tượng ổ khóa).',
    ],
  ),
  (
    'Samsung',
    ['Cài đặt → Chăm sóc thiết bị → Pin → Giới hạn sử dụng nền → thêm app vào “Ứng dụng không bao giờ ngủ”.'],
  ),
  (
    'Oppo / Realme',
    ['Cài đặt → Pin → (Quản lý pin ứng dụng) → Throttle Path → cho phép hoạt động nền, tắt “Tối ưu hóa”.'],
  ),
  (
    'Vivo',
    ['Cài đặt → Pin → Mức tiêu thụ pin nền cao → bật cho Throttle Path.'],
  ),
];

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.ok,
    required this.title,
    this.subtitle,
    required this.action,
    required this.onTap,
  });

  final int index;
  final bool? ok;
  final String title;
  final String? subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final good = ok == true;
    final bad = ok == false;
    final c = good ? context.colors.success : (bad ? context.cs.error : context.colors.idle);
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: bad ? c.withValues(alpha: 0.5) : context.cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: good ? c : c.withValues(alpha: 0.14),
                    ),
                    child: Center(
                      child: good
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                          : ok == null
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c))
                              : Text('$index', style: context.text.titleMedium?.copyWith(color: c)),
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(title, style: context.text.titleMedium),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: context.text.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (bad) ...[
                const SizedBox(height: Gap.md),
                FilledButton(onPressed: onTap, child: Text(action)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OemCard extends StatelessWidget {
  const _OemCard({required this.brand, required this.steps});

  final String brand;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: IconBadge(Icons.smartphone_rounded, color: context.cs.primary, size: 36),
          title: Text(brand, style: context.text.titleMedium),
          childrenPadding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: Gap.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(color: context.cs.surfaceContainerHigh, shape: BoxShape.circle),
                      child: Center(child: Text('${i + 1}', style: context.text.labelSmall)),
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(child: Text(steps[i], style: context.text.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
