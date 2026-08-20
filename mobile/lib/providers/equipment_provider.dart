import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../core/storage/app_database.dart';
import '../models/equipment.dart';
import 'database_provider.dart';

class EquipmentRepository {
  final AppDatabase db;
  EquipmentRepository(this.db);

  /// Looks up an equipment by its scanned QR token. Tries the network first
  /// (so status/history are fresh) and falls back to the local cache when
  /// offline, so scanning still works in a signal-dead basement.
  Future<Equipment> findByQrToken(String qrToken) async {
    try {
      final res = await DioClient.instance.get('/equipments/qr/$qrToken');
      final equipment = Equipment.fromJson(res.data);
      await db.cacheEquipment(CachedEquipmentsCompanion.insert(
        id: Value(equipment.id),
        name: equipment.name,
        reference: Value(equipment.reference),
        qrToken: equipment.qrToken,
        category: Value(equipment.category),
        location: Value(equipment.location),
        status: equipment.status,
        manufacturer: Value(equipment.manufacturer),
        model: Value(equipment.model),
        serialNumber: Value(equipment.serialNumber),
        notes: Value(equipment.notes),
      ));
      return equipment;
    } catch (_) {
      final cached = await db.findCachedByQrToken(qrToken);
      if (cached == null) rethrow;
      return Equipment(
        id: cached.id,
        name: cached.name,
        reference: cached.reference,
        qrToken: cached.qrToken,
        category: cached.category,
        location: cached.location,
        status: cached.status,
        manufacturer: cached.manufacturer,
        model: cached.model,
        serialNumber: cached.serialNumber,
        notes: cached.notes,
      );
    }
  }
}

final equipmentRepositoryProvider = Provider<EquipmentRepository>((ref) {
  return EquipmentRepository(ref.watch(databaseProvider));
});
