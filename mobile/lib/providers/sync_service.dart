import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../core/storage/app_database.dart';
import 'database_provider.dart';

/// Flushes queued offline actions (fault reports, interventions) to the API
/// as soon as connectivity is available.
class SyncService {
  final AppDatabase db;
  bool _syncing = false;

  SyncService(this.db) {
    Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        flush();
      }
    });
  }

  Future<void> flush() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final actions = await db.pendingActions();
      for (final action in actions) {
        final ok = await _send(action);
        if (ok) {
          await db.removeAction(action.id);
        }
      }
    } finally {
      _syncing = false;
    }
  }

  Future<bool> _send(OutboxAction action) async {
    final payload = jsonDecode(action.payloadJson) as Map<String, dynamic>;

    try {
      if (action.type == 'ticket') {
        final formMap = <String, dynamic>{
          'equipment_id': payload['equipment_id'],
          'title': payload['title'],
          if (payload['description'] != null) 'description': payload['description'],
          'priority': payload['priority'],
        };
        if (payload['photo_path'] != null) {
          formMap['photo'] = await MultipartFile.fromFile(payload['photo_path']);
        }
        if (payload['voice_note_path'] != null) {
          formMap['voice_note'] = await MultipartFile.fromFile(payload['voice_note_path']);
        }
        await DioClient.instance.post('/tickets', data: FormData.fromMap(formMap));
      } else if (action.type == 'intervention') {
        final formMap = <String, dynamic>{
          'equipment_id': payload['equipment_id'],
          if (payload['ticket_id'] != null) 'ticket_id': payload['ticket_id'],
          if (payload['work_order_id'] != null) 'work_order_id': payload['work_order_id'],
          if (payload['comment'] != null) 'comment': payload['comment'],
          if (payload['duration_minutes'] != null) 'duration_minutes': payload['duration_minutes'],
        };
        if (payload['photo_path'] != null) {
          formMap['photo'] = await MultipartFile.fromFile(payload['photo_path']);
        }
        if (payload['signature_path'] != null) {
          formMap['signature'] = await MultipartFile.fromFile(payload['signature_path']);
        }
        final parts = (payload['parts'] as List?) ?? [];
        for (var i = 0; i < parts.length; i++) {
          formMap['parts[$i][part_id]'] = parts[i]['part_id'];
          formMap['parts[$i][quantity]'] = parts[i]['quantity'];
        }
        await DioClient.instance.post('/interventions', data: FormData.fromMap(formMap));
      }
      return true;
    } on DioException catch (e) {
      // Keep the action queued on network errors; drop it on a definitive
      // rejection (validation error) so the queue doesn't jam forever.
      if (e.response != null && e.response!.statusCode! < 500) {
        return true;
      }
      return false;
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(databaseProvider));
});
