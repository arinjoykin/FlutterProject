enum UserRole {
  admin,
  user,
}

extension UserRoleExtension on UserRole {
  String get stringValue => this == UserRole.admin ? 'admin' : 'user';
  
  String get displayName => this == UserRole.admin ? 'Администратор' : 'Пользователь';
  
  bool get canManageProducts => this == UserRole.admin;
}

class UserAccount {
  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  UserAccount copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.stringValue,
    'createdAt': createdAt.toIso8601String(),
  };
}