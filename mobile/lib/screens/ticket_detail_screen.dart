import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/ticket_provider.dart';
import '../widgets/status_chip.dart';

class TicketDetailScreen extends ConsumerWidget {
  final int ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket')),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Padding(padding: EdgeInsets.all(24), child: Text('Impossible de charger ce ticket.')),
        data: (ticket) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ticket.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(ticket.equipment?.name ?? '', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Row(children: [
                StatusChip(label: ticket.priorityLabel, color: priorityColor(ticket.priority)),
                const SizedBox(width: 8),
                StatusChip(label: ticket.statusLabel, color: ticketStatusColor(ticket.status)),
              ]),
              if (ticket.description != null) ...[
                const SizedBox(height: 16),
                Text(ticket.description!),
              ],
              const Spacer(),
              if (ticket.status != 'closed')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Clôturer l'intervention"),
                    onPressed: () => context.push('/close-intervention', extra: {
                      'equipment_id': ticket.equipmentId,
                      'equipment_name': ticket.equipment?.name ?? '',
                      'ticket_id': ticket.id,
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
