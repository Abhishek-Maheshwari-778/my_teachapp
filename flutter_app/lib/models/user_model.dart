class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final bool isAdmin;
  final String sessionToken;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.isAdmin,
    required this.sessionToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isAdmin: json['is_admin'] == true || json['is_admin']?.toString() == 'true',
      sessionToken: json['session_token']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'is_admin': isAdmin,
      'session_token': sessionToken,
    };
  }
}

