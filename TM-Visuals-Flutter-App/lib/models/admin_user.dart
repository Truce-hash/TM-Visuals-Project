class AdminUser {
  final String userId;
  final String adminId;
  String name;
  String email;
  String role;
  String business;
  List<String> servicesList;
  String whatsapp;
  int bookings;
  int invoices;
  int contentDone;

  AdminUser({
    required this.userId,
    required this.adminId,
    required this.name,
    required this.email,
    required this.role,
    required this.business,
    required this.servicesList,
    required this.whatsapp,
    required this.bookings,
    required this.invoices,
    required this.contentDone,
  });

  factory AdminUser.fromJson(
    Map<String, dynamic> json, {
    int bookings = 0,
    int invoices = 0,
    int contentDone = 0,
  }) {
    Map<String, dynamic> adminMap = {};
    final adminData = json['admin'];
    if (adminData is Map<String, dynamic>) {
      adminMap = adminData;
    } else if (adminData is List && adminData.isNotEmpty) {
      adminMap = adminData.first as Map<String, dynamic>;
    }

    List<dynamic> rawServicesList = [];
    final serviceData = json['service'];
    if (serviceData is List) {
      rawServicesList = serviceData;
    } else if (serviceData is Map) {
      if (serviceData.containsKey('service_name')) {
        rawServicesList = [serviceData];
      } else {
        rawServicesList = serviceData.values.toList();
      }
    }

    List<String> parsedServices = [];
    for (var item in rawServicesList) {
      if (item is Map) {
        final name = item['service_name']?.toString() ?? '';
        if (name.isNotEmpty) {
          parsedServices.add(name);
        }
      }
    }

    return AdminUser(
      userId: json['user_id'] ?? '',
      adminId: adminMap['admin_id']?.toString() ?? '',
      name: json['full_name'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Admin',
      business: adminMap['business_name'] ?? '',
      servicesList: parsedServices.isNotEmpty
          ? parsedServices
          : ['Photo', 'Videos', 'Combined'],
      whatsapp: json['phone'] ?? '',
      bookings: bookings,
      invoices: invoices,
      contentDone: contentDone,
    );
  }
}
