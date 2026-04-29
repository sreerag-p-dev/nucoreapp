class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool disabled;
  final String createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.disabled,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      disabled: json['disabled'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
    );
  }

  UserModel copyWith({bool? disabled}) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      role: role,
      disabled: disabled ?? this.disabled,
      createdAt: createdAt,
    );
  }
}

class AuthUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String createdAt;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}
