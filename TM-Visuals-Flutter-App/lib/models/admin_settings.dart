class AdminSettings {
  String password;
  String email;
  String phone;

  AdminSettings(
      {required this.password, required this.email, required this.phone});

  AdminSettings copyWith({String? password, String? email, String? phone}) {
    return AdminSettings(
      password: password ?? this.password,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  factory AdminSettings.fromJson(Map<String, dynamic> json) {
    return AdminSettings(
      password: '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}