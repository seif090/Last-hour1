import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/brand_colors.dart';
import '../../theme/brand_typography.dart';

/// LIVE NOW badge with animated ping dot.
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: BrandColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: Stack(
              children: [
                FadeTransition(
                  opacity: _controller.drive(CurveTween(curve: const Interval(0, 0.5))),
                  child: ScaleTransition(
                    scale: _controller.drive(Tween(begin: 1, end: 2.5)),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: BrandColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: BrandColors.primary, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text('LIVE NOW', style: BrandTypography.labelBold(color: BrandColors.primary)),
        ],
      ),
    );
  }
}

/// Countdown chip — dark container with crimson border + timer text.
class CountdownChip extends StatefulWidget {
  final DateTime endTime;
  const CountdownChip({super.key, required this.endTime});

  @override
  State<CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<CountdownChip> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final rem = widget.endTime.difference(DateTime.now());
    if (rem.isNegative) {
      _timer?.cancel();
      setState(() => _remaining = Duration.zero);
    } else {
      setState(() => _remaining = rem);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final urgent = _remaining.inSeconds < 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: BrandColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: urgent ? BrandColors.primary : BrandColors.primary.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: BrandTypography.timerXl(color: BrandColors.primary).copyWith(
          fontSize: 14,
          height: 1,
          fontWeight: FontWeight.w900,
          fontFeatures: const [FontFeature.tabularNumbers()],
        ),
        child: Text(_format(_remaining)),
      ),
    );
  }
}

/// Inventory stock bar — thin crimson track with shimmer on low stock.
class InventoryBar extends StatelessWidget {
  final int current;
  final int max;
  const InventoryBar({super.key, required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final low = pct < 0.1;
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: Container(
            height: 6,
            width: constraints.maxWidth,
            color: BrandColors.surfaceDim,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: constraints.maxWidth * pct,
                decoration: BoxDecoration(
                  color: BrandColors.primary,
                  borderRadius: BorderRadius.circular(9999),
                  gradient: low
                      ? LinearGradient(
                          colors: [
                            BrandColors.primary,
                            BrandColors.primary.withOpacity(0.6),
                            BrandColors.primary,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
