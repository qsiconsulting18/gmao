import 'equipment.dart';

class Ticket {
  final int id;
  final int equipmentId;
  final Equipment? equipment;
  final String title;
  final String? description;
  final String? photoPath;
  final String priority;
  final String status;
  final String createdAt;
  final String? assigneeName;

  Ticket({
    required this.id,
    required this.equipmentId,
    this.equipment,
    required this.title,
    this.description,
    this.photoPath,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.assigneeName,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      equipmentId: json['equipment_id'],
      equipment: json['equipment'] != null ? Equipment.fromJson(json['equipment']) : null,
      title: json['title'],
      description: json['description'],
      photoPath: json['photo_path'],
      priority: json['priority'],
      status: json['status'],
      createdAt: json['created_at'],
      assigneeName: json['assignee']?['name'],
    );
  }

  String get priorityLabel => switch (priority) {
        'low' => 'Basse',
        'medium' => 'Moyenne',
        'high' => 'Haute',
        'urgent' => 'Urgente',
        _ => priority,
      };

  String get statusLabel => switch (status) {
        'open' => 'Ouvert',
        'assigned' => 'Assigné',
        'in_progress' => 'En cours',
        'closed' => 'Clôturé',
        _ => status,
      };
}
