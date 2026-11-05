class AdminSettings {
  String currentPassword;
  String newPassword;
  String confirmPassword;
  String email;
  String phone;

  AdminSettings({
    this.currentPassword = '',
    this.newPassword = '',
    this.confirmPassword = '',
    required this.email,
    required this.phone,
  });
}
