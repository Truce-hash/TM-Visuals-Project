class AdminUser {
  final String name;
  final String email;
  final String role;
  final String business;
  final String services;
  final String whatsapp;
  final int bookings;
  final int invoices;
  final int contentDone;

  const AdminUser({
    required this.name,
    required this.email,
    required this.role,
    required this.business,
    required this.services,
    required this.whatsapp,
    required this.bookings,
    required this.invoices,
    required this.contentDone,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      business: json['business'] ?? '',
      services: json['services'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      bookings: json['bookings'] ?? 0,
      invoices: json['invoices'] ?? 0,
      contentDone: json['content_done'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'role': role,
        'business': business,
        'services': services,
        'whatsapp': whatsapp,
        'content_done': contentDone,
      };
}