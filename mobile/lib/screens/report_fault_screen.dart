import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../core/network/dio_client.dart';
import '../models/equipment.dart';
import '../providers/database_provider.dart';
import '../providers/sync_service.dart';

class ReportFaultScreen extends ConsumerStatefulWidget {
  final Equipment equipment;
  const ReportFaultScreen({super.key, required this.equipment});

  @override
  ConsumerState<ReportFaultScreen> createState() => _ReportFaultScreenState();
}

class _ReportFaultScreenState extends ConsumerState<ReportFaultScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  String _priority = 'medium';
  File? _photo;
  File? _voiceNote;
  bool _recording = false;
  bool _submitting = false;

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() {
        _recording = false;
        _voiceNote = path != null ? File(path) : null;
      });
      return;
    }

    if (!await _recorder.hasPermission()) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/note_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    setState(() => _recording = true);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _submitting = true);

    final db = ref.read(databaseProvider);
    var queued = false;

    try {
      final formMap = <String, dynamic>{
        'equipment_id': widget.equipment.id,
        'title': _titleController.text.trim(),
        if (_descriptionController.text.trim().isNotEmpty) 'description': _descriptionController.text.trim(),
        'priority': _priority,
      };
      if (_photo != null) {
        formMap['photo'] = await MultipartFile.fromFile(_photo!.path);
      }
      if (_voiceNote != null) {
        formMap['voice_note'] = await MultipartFile.fromFile(_voiceNote!.path);
      }
      await DioClient.instance.post('/tickets', data: FormData.fromMap(formMap));
    } on DioException {
      // Likely offline — queue for later sync instead of losing the report.
      await db.queueAction('ticket', jsonEncode({
        'equipment_id': widget.equipment.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'priority': _priority,
        'photo_path': _photo?.path,
        'voice_note_path': _voiceNote?.path,
      }));
      queued = true;
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(queued ? "Hors ligne : le signalement sera envoyé dès le retour du réseau." : 'Panne signalée avec succès.'),
    ));
    ref.read(syncServiceProvider).flush();
    context.go('/');
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Signaler une panne — ${widget.equipment.name}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Que se passe-t-il ? *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Commentaire (optionnel)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: const InputDecoration(labelText: 'Priorité'),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Basse')),
              DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
              DropdownMenuItem(value: 'high', child: Text('Haute')),
              DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
            ],
            onChanged: (v) => setState(() => _priority = v!),
          ),
          const SizedBox(height: 16),
          if (_photo != null)
            ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_photo!, height: 180, fit: BoxFit.cover)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(_photo == null ? 'Prendre une photo' : 'Reprendre la photo'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _toggleRecording,
                icon: Icon(_recording ? Icons.stop_circle_outlined : Icons.mic_none),
                label: Text(_recording ? 'Arrêter' : 'Note vocale'),
              ),
              if (_voiceNote != null && !_recording) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _player.play(DeviceFileSource(_voiceNote!.path)),
                  icon: const Icon(Icons.play_circle_outline),
                ),
                IconButton(
                  onPressed: () => setState(() => _voiceNote = null),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Envoi…' : 'Envoyer le signalement'),
          ),
        ],
      ),
    );
  }
}
