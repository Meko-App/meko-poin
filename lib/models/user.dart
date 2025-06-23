class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final int roleId;
  final DateTime? deletedAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.roleId,
    this.deletedAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      roleId: map['role_id'],
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
      deletedAt: null,
    );
  }

  bool get isDeleted => deletedAt != null;
}
