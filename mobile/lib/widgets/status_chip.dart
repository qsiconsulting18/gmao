import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

Color equipmentStatusColor(String status) => switch (status) {
      'operational' => const Color(0xFF059669),
      'down' => const Color(0xFFDC2626),
      'maintenance' => const Color(0xFFD97706),
      _ => const Color(0xFF64748B),
    };

Color priorityColor(String priority) => switch (priority) {
      'urgent' => const Color(0xFFDC2626),
      'high' => const Color(0xFFD97706),
      _ => const Color(0xFF64748B),
    };

Color ticketStatusColor(String status) => switch (status) {
      'open' => const Color(0xFFDC2626),
      'assigned' => const Color(0xFF2563EB),
      'in_progress' => const Color(0xFFD97706),
      'closed' => const Color(0xFF059669),
      _ => const Color(0xFF64748B),
    };
