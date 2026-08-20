import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/equipment.dart';
import '../providers/equipment_provider.dart';
import '../widgets/status_chip.dart';

final _equipmentByQrProvider = FutureProvider.autoDispose.family<Equipment, String>((ref, qrToken) {
  return ref.watch(equipmentRepositoryProvider).findByQrToken(qrToken);
});

class EquipmentDetailScreen extends ConsumerWidget {
  final String qrToken;
  const EquipmentDetailScreen({super.key, required this.qrToken});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentAsync = ref.watch(_equipmentByQrProvider(qrToken));

    return Scaffold(
      appBar: AppBar(title: const Text('Équipement')),
      body: equipmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Équipement introuvable pour ce QR Code.\n\n$e', textAlign: TextAlign.center),
        ),
        data: (equipment) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(equipment.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(equipment.location ?? '', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              StatusChip(label: equipment.statusLabel, color: equipmentStatusColor(equipment.status)),
              const SizedBox(height: 24),
              _InfoRow(label: 'Référence', value: equipment.reference),
              _InfoRow(label: 'Fabricant', value: equipment.manufacturer),
              _InfoRow(label: 'Modèle', value: equipment.model),
              _InfoRow(label: 'N° de série', value: equipment.serialNumber),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.report_problem_outlined),
                  label: const Text('Signaler une panne'),
                  onPressed: () => context.push('/report-fault', extra: equipment),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  const _InfoRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value ?? '—')),
        ],
      ),
    );
  }
}
