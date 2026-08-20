import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../providers/work_order_provider.dart';
import '../widgets/status_chip.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(auth.tenant?.name ?? 'GMAO Léger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: _tab == 0 ? const _TicketsTab() : const _WorkOrdersTab(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scan'),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scanner'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Tickets'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Bons de travail'),
        ],
      ),
    );
  }
}

class _TicketsTab extends ConsumerWidget {
  const _TicketsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(myTicketsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(myTicketsProvider.future),
      child: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: const [Padding(padding: EdgeInsets.all(24), child: Text('Impossible de charger les tickets. Vérifiez votre connexion.'))]),
        data: (tickets) {
          if (tickets.isEmpty) {
            return ListView(children: const [Padding(padding: EdgeInsets.all(24), child: Text('Aucun ticket pour le moment.'))]);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: tickets.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final ticket = tickets[i];
              return Card(
                child: ListTile(
                  title: Text(ticket.title),
                  subtitle: Text(ticket.equipment?.name ?? ''),
                  trailing: StatusChip(label: ticket.statusLabel, color: ticketStatusColor(ticket.status)),
                  onTap: () => context.push('/tickets/${ticket.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WorkOrdersTab extends ConsumerWidget {
  const _WorkOrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workOrdersAsync = ref.watch(myWorkOrdersProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(myWorkOrdersProvider.future),
      child: workOrdersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: const [Padding(padding: EdgeInsets.all(24), child: Text('Impossible de charger les bons de travail.'))]),
        data: (workOrders) {
          if (workOrders.isEmpty) {
            return ListView(children: const [Padding(padding: EdgeInsets.all(24), child: Text('Aucun bon de travail à venir.'))]);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: workOrders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final wo = workOrders[i];
              return Card(
                child: ListTile(
                  title: Text(wo.title),
                  subtitle: Text('${wo.equipment?.name ?? ''} · échéance ${wo.dueDate}'),
                  trailing: StatusChip(label: wo.statusLabel, color: equipmentStatusColor(wo.status == 'pending' ? 'maintenance' : 'operational')),
                  onTap: () => context.push('/close-intervention', extra: {
                    'equipment_id': wo.equipmentId,
                    'equipment_name': wo.equipment?.name ?? '',
                    'work_order_id': wo.id,
                  }),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
