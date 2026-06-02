import 'package:flutter/material.dart';
import 'package:lasthour_shared/models/order.dart';

class StatusTimeline extends StatelessWidget {
  final List<StatusHistory> statusHistory;
  final String? currentStatus;

  const StatusTimeline({
    super.key,
    required this.statusHistory,
    this.currentStatus,
  });

  final _statusOrder = const [
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'pickedUp',
  ];

  @override
  Widget build(BuildContext context) {
    final entries = _statusOrder.map((s) {
      final match = statusHistory.where((h) => h.status == s).toList();
      final latest = match.isNotEmpty ? match.last : null;
      return (status: s, time: latest?.at);
    }).toList();

    return Column(
      children: entries.map((entry) {
        final isActive = entry.time != null;
        final isLast = entries.last.status == entry.status;
        final isCurrent = entry.status == currentStatus;

        return _buildStep(
          context,
          label: _labelFor(entry.status),
          time: entry.time,
          isActive: isActive,
          isLast: isLast,
          isCurrent: isCurrent,
        );
      }).toList(),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required String label,
    required DateTime? time,
    required bool isActive,
    required bool isLast,
    required bool isCurrent,
  }) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: isCurrent ? 20 : 14,
                  height: isCurrent ? 20 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                    border: isCurrent ? Border.all(color: theme.colorScheme.surface, width: 3) : null,
                    boxShadow: isCurrent
                        ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.4), blurRadius: 8)]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.3) : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isCurrent ? 16 : 14,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(time),
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _labelFor(String status) {
    switch (status) {
      case 'pending':
        return 'Order placed';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for pickup';
      case 'pickedUp':
        return 'Picked up';
      default:
        return status;
    }
  }
}
