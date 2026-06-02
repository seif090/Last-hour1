import 'dart:async';
import 'package:flutter/material.dart';

class OfferTimer extends StatefulWidget {
  final DateTime endTime;

  const OfferTimer({super.key, required this.endTime});

  @override
  State<OfferTimer> createState() => _OfferTimerState();
}

class _OfferTimerState extends State<OfferTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final remaining = widget.endTime.difference(DateTime.now());
    if (remaining.isNegative) {
      _timer?.cancel();
      setState(() => _remaining = Duration.zero);
    } else {
      setState(() => _remaining = remaining);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative || _remaining.inSeconds == 0) {
      return const SizedBox();
    }

    final theme = Theme.of(context);
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    String text;
    Color color;

    if (hours > 0) {
      text = '${hours}h ${minutes.toString().padLeft(2, '0')}m';
      color = theme.colorScheme.onSurfaceVariant;
    } else if (minutes > 0) {
      text = '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
      color = theme.colorScheme.secondary;
    } else {
      text = '${seconds}s';
      color = theme.colorScheme.error;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
