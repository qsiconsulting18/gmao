import 'equipment.dart';

class WorkOrder {
  final int id;
  final int equipmentId;
  final Equipment? equipment;
  final String type;
  final String title;
  final String status;
  final String dueDate;

  WorkOrder({
    required this.id,
    required this.equipmentId,
    this.equipment,
    required this.type,
    required this.title,
    required this.status,
    required this.dueDate,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id'],
      equipmentId: json['equipment_id'],
      equipment: json['equipment'] != null ? Equipment.fromJson(json['equipment']) : null,
      type: json['type'],
      title: json['title'],
      status: json['status'],
      dueDate: json['due_date'],
    );
  }

  String get statusLabel => switch (status) {
        'pending' => 'À faire',
        'in_progress' => 'En cours',
        'completed' => 'Terminé',
        'cancelled' => 'Annulé',
        _ => status,
      };
}
