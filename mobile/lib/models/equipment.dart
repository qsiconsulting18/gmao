class Equipment {
  final int id;
  final String name;
  final String? reference;
  final String qrToken;
  final String? category;
  final String? location;
  final String status;
  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final String? notes;

  Equipment({
    required this.id,
    required this.name,
    this.reference,
    required this.qrToken,
    this.category,
    this.location,
    required this.status,
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.notes,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'],
      name: json['name'],
      reference: json['reference'],
      qrToken: json['qr_token'],
      category: json['category'],
      location: json['location'],
      status: json['status'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      serialNumber: json['serial_number'],
      notes: json['notes'],
    );
  }

  String get statusLabel => switch (status) {
        'operational' => 'Opérationnel',
        'down' => 'En panne',
        'maintenance' => 'En maintenance',
        _ => status,
      };
}
