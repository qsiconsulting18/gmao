class Part {
  final int id;
  final String name;
  final String? reference;
  final String unit;
  final int quantityOnHand;

  Part({
    required this.id,
    required this.name,
    this.reference,
    required this.unit,
    required this.quantityOnHand,
  });

  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(
      id: json['id'],
      name: json['name'],
      reference: json['reference'],
      unit: json['unit'],
      quantityOnHand: json['quantity_on_hand'],
    );
  }
}

class PartUsage {
  final Part part;
  int quantity;

  PartUsage({required this.part, this.quantity = 1});
}
