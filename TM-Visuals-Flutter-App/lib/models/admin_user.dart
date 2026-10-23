class AdminUser {
  String name;
  String email;
  String role;
  String business;
  String services;
  String whatsapp;
  int bookings;
  int invoices;
  int contentDone;

  AdminUser({
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
}