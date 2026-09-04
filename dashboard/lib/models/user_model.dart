class UserModel {
  final String uid;
  final String name;
  final String role;
  final String phone;

  const UserModel({
    required this.uid,
    required this.name,
    required this.role,
    required this.phone,
  });

  factory UserModel.fromJson(String uid, Map<String, dynamic> json) {
    return UserModel(
      uid: uid,
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'volunteer',
      phone: json['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'phone': phone,
    };
  }

  static const String roleAdmin = 'admin';
  static const String roleVolunteer = 'volunteer';
}
