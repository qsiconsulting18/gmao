class AppUser {
  final int id;
  final int tenantId;
  final String name;
  final String email;
  final String role;
  final String? phone;

  AppUser({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      tenantId: json['tenant_id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      phone: json['phone'],
    );
  }

  bool get isTechnician => role == 'technician';
  bool get isManagerOrAdmin => role == 'manager' || role == 'admin';
}

class Tenant {
  final int id;
  final String name;

  Tenant({required this.id, required this.name});

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(id: json['id'], name: json['name']);
  }
}
