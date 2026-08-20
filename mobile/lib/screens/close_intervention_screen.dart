import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import '../core/network/dio_client.dart';
import '../models/part.dart';
import '../providers/database_provider.dart';
import '../providers/part_provider.dart';
import '../providers/sync_service.dart';

class CloseInterventionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> extra;
  const CloseInterventionScreen({super.key, required this.extra});

  @override
  ConsumerState<CloseInterventionScreen> createState() => _CloseInterventionScreenState();
}

class _CloseInterventionScreenState extends ConsumerState<CloseInterventionScreen> {
  final _commentController = TextEditingController();
  final _durationController = TextEditingController();
  final _signatureController = SignatureController(penStrokeWidth: 3, penColor: Colors.black);
  final Map<int, PartUsage> _selectedParts = {};
  File? _photo;
  bool _submitting = false;

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  void _togglePart(Part part, bool selected) {
    setState(() {
      if (selected) {
        _selectedParts[part.id] = PartUsage(part: part);
      } else {
        _selectedParts.remove(part.id);
      }
    });
  }

  Future<String?> _saveSignature() async {
    if (_signatureController.isEmpty) return null;
    final bytes = await _signatureController.toPngBytes();
    if (bytes == null) return null;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final db = ref.read(databaseProvider);
    final signaturePath = await _saveSignature();
    var queued = false;

    final partsPayload = _selectedParts.values.map((u) => {'part_id': u.part.id, 'quantity': u.quantity}).toList();

    try {
      final formMap = <String, dynamic>{
        'equipment_id': widget.extra['equipment_id'],
        if (widget.extra['ticket_id'] != null) 'ticket_id': widget.extra['ticket_id'],
        if (widget.extra['work_order_id'] != null) 'work_order_id': widget.extra['work_order_id'],
        if (_commentController.text.trim().isNotEmpty) 'comment': _commentController.text.trim(),
        if (_durationController.text.trim().isNotEmpty) 'duration_minutes': int.tryParse(_durationController.text.trim()),
      };
      if (_photo != null) formMap['photo'] = await MultipartFile.fromFile(_photo!.path);
      if (signaturePath != null) formMap['signature'] = await MultipartFile.fromFile(signaturePath);
      for (var i = 0; i < partsPayload.length; i++) {
        formMap['parts[$i][part_id]'] = partsPayload[i]['part_id'];
        formMap['parts[$i][quantity]'] = partsPayload[i]['quantity'];
      }
      await DioClient.instance.post('/interventions', data: FormData.fromMap(formMap));
    } on DioException {
      await db.queueAction('intervention', jsonEncode({
        'equipment_id': widget.extra['equipment_id'],
        'ticket_id': widget.extra['ticket_id'],
        'work_order_id': widget.extra['work_order_id'],
        'comment': _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        'duration_minutes': int.tryParse(_durationController.text.trim()),
        'photo_path': _photo?.path,
        'signature_path': signaturePath,
        'parts': partsPayload,
      }));
      queued = true;
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(queued ? "Hors ligne : l'intervention sera envoyée dès le retour du réseau." : 'Intervention enregistrée.'),
    ));
    ref.read(syncServiceProvider).flush();
    context.go('/');
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partsAsync = ref.watch(partsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Clôture — ${widget.extra['equipment_name'] ?? ''}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Temps passé (minutes)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: "Compte-rendu de l'intervention"),
          ),
          const SizedBox(height: 20),
          const Text('Pièces utilisées', style: TextStyle(fontWeight: FontWeight.bold)),
          partsAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
            error: (e, _) => const Text('Liste des pièces indisponible hors ligne.'),
            data: (parts) => Column(
              children: parts.map((part) {
                final selected = _selectedParts.containsKey(part.id);
                return Card(
                  child: CheckboxListTile(
                    title: Text(part.name),
                    subtitle: Text('${part.quantityOnHand} ${part.unit} en stock'),
                    value: selected,
                    onChanged: (v) => _togglePart(part, v ?? false),
                    secondary: selected
                        ? SizedBox(
                            width: 70,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Qté'),
                              onChanged: (v) => _selectedParts[part.id]!.quantity = int.tryParse(v) ?? 1,
                            ),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Photo du travail réalisé', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_photo != null)
            ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_photo!, height: 160, fit: BoxFit.cover)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(_photo == null ? 'Prendre une photo' : 'Reprendre la photo'),
          ),
          const SizedBox(height: 20),
          const Text('Signature du responsable', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 180,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
            child: Signature(controller: _signatureController, backgroundColor: Colors.white),
          ),
          TextButton(onPressed: () => _signatureController.clear(), child: const Text('Effacer la signature')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Enregistrement…' : "Valider l'intervention"),
          ),
        ],
      ),
    );
  }
}
