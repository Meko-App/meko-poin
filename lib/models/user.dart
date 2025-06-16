class User {
  final int id;
  final String name;
  final String email;
  final String password;
  final int roleId;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.roleId,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      roleId: map['role_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role_id': roleId,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    int? roleId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      roleId: roleId ?? this.roleId,
    );
  }
}
