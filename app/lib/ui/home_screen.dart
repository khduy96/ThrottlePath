import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../recorder/protocol.dart';
import 'export_screen.dart';
import 'format.dart';
import 'places_screen.dart';
import 'setup_screen.dart';
import 'theme/app_theme.dart';
import 'trips_screen.dart';
import 'widgets/common.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(recorderProvider.notifier).refresh();
      ref.invalidate(tripsProvider);
    }
  }

  Future<void> _run(Future<String?> Function() action) async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _busy = true);
    final err = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  void _open(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    ref.listen(recorderProvider, (prev, next) {
      final event = next.lastEvent;
      if (event != null && event != prev?.lastEvent) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(event)));
        ref.read(recorderProvider.notifier).clearEvent();
      }
    });
    final status = ref.watch(recorderProvider);
    final places = ref.watch(placesProvider).value ?? const [];
    final trips = ref.watch(tripsProvider).value ?? const [];
    final lastTrip = trips.where((t) => t.endedAt != null).firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xxl),
          children: [
            const _Header(),
            const SizedBox(height: Gap.lg),
            _StatusHero(status: status),
            const SizedBox(height: Gap.lg),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(status.phase), child: _actions(status)),
            ),
            if (places.isEmpty) ...[
              const SizedBox(height: Gap.lg),
              _Banner(
                icon: Icons.add_location_alt_rounded,
                title: 'Chưa nhập địa điểm',
                message: 'Nhập Nhà, Công ty, Cửa Hàng để app biết lúc bạn rời đi và lúc tới nơi.',
                onTap: () => _open(const PlacesScreen()),
              ),
            ],
            if (lastTrip != null) ...[
              SectionHeader(
                'Chuyến gần nhất',
                trailing: TextButton(onPressed: () => _open(const TripsScreen()), child: const Text('Xem tất cả')),
              ),
              TripCard(trip: lastTrip),
            ],
            const SectionHeader('Công cụ'),
            TwoColumnGrid(
              children: [
                _NavTile(
                  icon: Icons.route_rounded,
                  color: context.colors.evening1,
                  title: 'Chuyến đi',
                  subtitle: trips.isEmpty ? 'Chưa có' : '${trips.length} chuyến',
                  onTap: () => _open(const TripsScreen()),
                ),
                _NavTile(
                  icon: Icons.place_rounded,
                  color: context.colors.morning,
                  title: 'Địa điểm',
                  subtitle: '${places.length}/3 đã nhập',
                  onTap: () => _open(const PlacesScreen()),
                ),
                _NavTile(
                  icon: Icons.battery_charging_full_rounded,
                  color: context.colors.success,
                  title: 'Quyền & pin',
                  subtitle: 'Để không bị tắt giữa chuyến',
                  onTap: () => _open(const SetupScreen()),
                ),
                _NavTile(
                  icon: Icons.ios_share_rounded,
                  color: context.colors.evening2,
                  title: 'Xuất dữ liệu',
                  subtitle: 'GPX & JSON',
                  onTap: () => _open(const ExportScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(RecorderStatus status) {
    final controller = ref.read(recorderProvider.notifier);
    Future<String?> stop() async {
      await controller.stop();
      return null;
    }

    switch (status.phase) {
      case RecorderPhase.off:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BigActionButton(
              icon: Icons.two_wheeler_rounded,
              label: 'SẴN SÀNG',
              sublabel: 'Tự ghi khi bạn rời chỗ',
              color: context.cs.primary,
              onColor: context.cs.onPrimary,
              onPressed: _busy ? null : () => _run(controller.arm),
            ),
            const SizedBox(height: Gap.md),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(controller.startNow),
              icon: const Icon(Icons.fiber_manual_record_rounded, size: 18),
              label: const Text('Ghi ngay (đã lỡ đi mà quên bấm)'),
            ),
          ],
        );
      case RecorderPhase.waiting:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BigActionButton(
              icon: Icons.fiber_manual_record_rounded,
              label: 'GHI NGAY',
              sublabel: 'Không cần chờ — bắt đầu ghi luôn',
              color: context.colors.waiting,
              onColor: Colors.black,
              onPressed: _busy ? null : () => _run(controller.startNow),
            ),
            const SizedBox(height: Gap.md),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(stop),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Hủy'),
            ),
          ],
        );
      case RecorderPhase.recording:
        return _BigActionButton(
          icon: Icons.stop_rounded,
          label: 'DỪNG',
          sublabel: 'App sẽ tự dừng khi tới nơi',
          color: context.colors.recording,
          onColor: Colors.white,
          onPressed: _busy ? null : () => _run(stop),
        );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = switch (now.hour) {
      < 11 => 'Chào buổi sáng',
      < 14 => 'Chào buổi trưa',
      < 18 => 'Chào buổi chiều',
      _ => 'Chào buổi tối',
    };
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fmtDay(now.millisecondsSinceEpoch),
                style: context.text.labelLarge?.copyWith(color: context.cs.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(greeting, style: context.text.headlineMedium),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [context.cs.primary, Color.lerp(context.cs.primary, Colors.red, 0.35)!],
            ),
          ),
          child: Icon(Icons.two_wheeler_rounded, color: context.cs.onPrimary),
        ),
      ],
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.status});

  final RecorderStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors.phase(status.phase);
    final (String chip, String title, String detail) = switch (status.phase) {
      RecorderPhase.off => (
          'TẮT',
          'Sẵn sàng đi?',
          'Bấm “Sẵn sàng” trước khi đi. App tự ghi khi bạn rời chỗ đang đứng.',
        ),
      RecorderPhase.waiting => (
          'CHỜ ĐI',
          'Đang chờ bạn đi',
          [
            if (status.since != null) 'Từ ${fmtTime(status.since!)}',
            status.originLabel != null ? 'đang ở ${status.originLabel}' : 'chưa ở địa điểm nào đã lưu',
          ].join(' · '),
        ),
      RecorderPhase.recording => (
          'ĐANG GHI',
          '',
          status.since != null ? 'Đi lúc ${fmtTime(status.since!)}' : '',
        ),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withValues(alpha: 0.20), c.withValues(alpha: 0.05)],
        ),
      ),
      padding: const EdgeInsets.all(Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (status.phase == RecorderPhase.off)
                Padding(
                  padding: const EdgeInsets.only(right: Gap.sm),
                  child: Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                )
              else
                Transform.translate(offset: const Offset(-8, 0), child: PulsingDot(color: c, size: 10)),
              Text(
                chip,
                style: context.text.labelLarge?.copyWith(color: c, fontWeight: FontWeight.w800, letterSpacing: 1.4),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          if (status.phase == RecorderPhase.recording) ...[
            if (status.since != null) _Elapsed(since: status.since!),
            const SizedBox(height: Gap.xs),
            Text(detail, style: context.text.bodyLarge?.copyWith(color: context.cs.onSurfaceVariant)),
            const SizedBox(height: Gap.lg),
            Row(
              children: [
                _HeroStat(value: (status.distanceM / 1000).toStringAsFixed(1), unit: 'km'),
                const SizedBox(width: Gap.xl),
                _HeroStat(value: '${status.points}', unit: 'điểm GPS'),
              ],
            ),
          ] else ...[
            Text(title, style: context.text.headlineLarge),
            const SizedBox(height: Gap.sm),
            Text(detail, style: context.text.bodyLarge?.copyWith(color: context.cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: value, style: context.text.headlineSmall?.copyWith(fontFeatures: tabular)),
        TextSpan(text: ' $unit', style: context.text.labelLarge?.copyWith(color: context.cs.onSurfaceVariant)),
      ]),
    );
  }
}

/// Live ride timer, ticking every second.
class _Elapsed extends StatefulWidget {
  const _Elapsed({required this.since});

  final int since;

  @override
  State<_Elapsed> createState() => _ElapsedState();
}

class _ElapsedState extends State<_Elapsed> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ((DateTime.now().millisecondsSinceEpoch - widget.since) / 1000).floor().clamp(0, 359999);
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
    final txt = h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
    return Text(txt, style: context.text.displayLarge?.copyWith(fontFeatures: tabular, height: 1));
  }
}

/// The one-tap button: tall, rounded, glowing in its colour.
class _BigActionButton extends StatelessWidget {
  const _BigActionButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final Color onColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.lg),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(Radii.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 112,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: onColor.withValues(alpha: 0.16)),
                      child: Icon(icon, size: 38, color: onColor),
                    ),
                    const SizedBox(width: Gap.lg),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: context.text.headlineMedium?.copyWith(
                              color: onColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(sublabel, style: context.text.bodyMedium?.copyWith(color: onColor.withValues(alpha: 0.85))),
                        ],
                      ),
                    ),
                    if (!enabled)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: onColor),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.title, required this.message, required this.onTap});

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors.warning;
    return Card(
      color: c.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: c.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Row(
            children: [
              IconBadge(icon, color: c),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleMedium),
                    const SizedBox(height: 2),
                    Text(message, style: context.text.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon, color: color),
              const SizedBox(height: Gap.md),
              Text(title, style: context.text.titleMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                style: context.text.bodySmall?.copyWith(color: context.cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
