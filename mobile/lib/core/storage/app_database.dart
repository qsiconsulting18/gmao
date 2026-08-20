import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class CachedEquipments extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get reference => text().nullable()();
  TextColumn get qrToken => text()();
  TextColumn get category => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get status => text()();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A pending write action (fault report or intervention) created while
/// offline, queued here until connectivity returns.
class OutboxActions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'ticket' | 'intervention'
  TextColumn get payloadJson => text()();
  TextColumn get createdAt => text()();
}

@DriftDatabase(tables: [CachedEquipments, OutboxActions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> cacheEquipment(CachedEquipmentsCompanion equipment) async {
    await into(cachedEquipments).insertOnConflictUpdate(equipment);
  }

  Future<CachedEquipment?> findCachedByQrToken(String qrToken) {
    return (select(cachedEquipments)..where((t) => t.qrToken.equals(qrToken))).getSingleOrNull();
  }

  Future<int> queueAction(String type, String payloadJson) {
    return into(outboxActions).insert(OutboxActionsCompanion.insert(
      type: type,
      payloadJson: payloadJson,
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  Future<List<OutboxAction>> pendingActions() => select(outboxActions).get();

  Future<void> removeAction(int id) => (delete(outboxActions)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gmao_mobile.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
