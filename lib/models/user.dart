class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final int roleId;
  final String? avatarPath;
  final DateTime? deletedAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.roleId,
    this.avatarPath,
    this.deletedAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      roleId: map['role_id'],
      avatarPath: map['avatar_path'],
      deletedAt:
          map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role_id': roleId,
      'avatar_path': avatarPath,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  User markAsDeleted() {
    return User(
      id: id,
      name: name,
      email: email,
      password: password,
      roleId: roleId,
      avatarPath: avatarPath,
      deletedAt: DateTime.now(),
    );
  }

  User restore() {
    return User(
      id: id,
      name: name,
      email: email,
      password: password,
      roleId: roleId,
      avatarPath: avatarPath,
      deletedAt: null,
    );
  }

  bool get isDeleted => deletedAt != null;
}
