import 'package:flutter/material.dart';

import '../../domain/place.dart';
import '../../domain/plans.dart';
import '../../domain/trip_analysis.dart';
import '../format.dart';
import '../theme/app_theme.dart';

IconData placeIcon(PlaceKind k) => switch (k) {
      PlaceKind.home => Icons.home_rounded,
      PlaceKind.work => Icons.business_rounded,
      PlaceKind.stop => Icons.storefront_rounded,
    };

/// Small all-caps label above a group of content.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xs, Gap.xl, Gap.xs, Gap.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: context.text.labelMedium?.copyWith(
                color: context.cs.onSurfaceVariant,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Rounded square with a tinted background and a coloured icon.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, required this.color, this.size = 44});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

/// A big number with a unit and a caption, for glanceable stats.
class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, this.unit, this.icon, this.color});

  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.cs.onSurface;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: context.cs.onSurfaceVariant),
                  const SizedBox(width: Gap.xs),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium?.copyWith(color: context.cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.sm),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: value),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: context.text.labelLarge?.copyWith(color: context.cs.onSurfaceVariant),
                  ),
              ]),
              style: context.text.headlineSmall?.copyWith(color: c, fontFeatures: tabular),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lays children out two per row with equal widths.
class TwoColumnGrid extends StatelessWidget {
  const TwoColumnGrid({super.key, required this.children, this.spacing = Gap.md});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: spacing));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: children[i]),
            SizedBox(width: spacing),
            Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

/// Coloured pill naming a plan.
class PlanChip extends StatelessWidget {
  const PlanChip(this.plan, {super.key});

  final PlanId? plan;

  @override
  Widget build(BuildContext context) {
    final c = context.colors.plan(plan);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            plan?.label ?? 'Không rõ plan',
            style: context.text.labelMedium?.copyWith(color: c, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// A dot that breathes, to show something is live.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, required this.color, this.size = 12});

  final Color color;
  final double size;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 2.6,
      height: s * 2.6,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: s + s * 1.6 * _c.value,
              height: s + s * 1.6 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.45 * (1 - _c.value)),
              ),
            ),
            Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
          ],
        ),
      ),
    );
  }
}

/// Friendly placeholder for empty lists and errors.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action, this.color});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.cs.primary;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [c.withValues(alpha: 0.22), c.withValues(alpha: 0.04)]),
              ),
              child: Icon(icon, size: 52, color: c),
            ),
            const SizedBox(height: Gap.xl),
            Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
            if (message != null) ...[
              const SizedBox(height: Gap.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant),
              ),
            ],
            if (action != null) ...[const SizedBox(height: Gap.xl), action!],
          ],
        ),
      ),
    );
  }
}

/// "2/3 done" header with a progress ring, for checklists.
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({super.key, required this.done, required this.total, required this.title, this.subtitle});

  final int done;
  final int total;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final complete = done >= total;
    final c = complete ? context.colors.success : context.cs.primary;
    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.md),
        gradient: LinearGradient(colors: [c.withValues(alpha: 0.16), c.withValues(alpha: 0.04)]),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: total == 0 ? 0 : done / total),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => CircularProgressIndicator(
                    value: v,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    color: c,
                    backgroundColor: c.withValues(alpha: 0.18),
                  ),
                ),
                Center(
                  child: complete
                      ? Icon(Icons.check_rounded, color: c, size: 28)
                      : Text('$done/$total', style: context.text.labelLarge?.copyWith(color: c, fontFeatures: tabular)),
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                if (subtitle != null)
                  Text(subtitle!, style: context.text.bodySmall?.copyWith(color: context.cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Muted explanatory note with an info icon.
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.icon = Icons.info_outline_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: context.cs.onSurfaceVariant),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Text(text, style: context.text.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

/// Proportional bar of a trip's legs (riding time) and stops.
class LegBar extends StatelessWidget {
  const LegBar({super.key, required this.legs, required this.color, this.showLabels = true});

  final List<LegResult> legs;
  final Color color;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final parts = <(double, bool, LegResult)>[];
    for (final l in legs) {
      parts.add((l.actualMin, false, l));
      if (l.stopMin != null && l.stopMin! > 0) parts.add((l.stopMin!, true, l));
    }
    final total = parts.fold<double>(0, (s, p) => s + p.$1);
    if (total <= 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                for (var i = 0; i < parts.length; i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    flex: (parts[i].$1 / total * 1000).round().clamp(1, 1000),
                    child: ColoredBox(
                      color: parts[i].$2
                          ? context.cs.outlineVariant
                          : color.withValues(alpha: i.isEven ? 1 : 0.65),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: Gap.sm),
          Wrap(
            spacing: Gap.md,
            runSpacing: Gap.xs,
            children: [
              for (final l in legs)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(placeIcon(l.to), size: 14, color: context.cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${l.to.label} ${fmtMin(l.actualMin)}',
                      style: context.text.labelMedium?.copyWith(
                        color: context.cs.onSurfaceVariant,
                        fontFeatures: tabular,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}
