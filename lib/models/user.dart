class User {
  final int? id;
  final String name;
  final String email;
  final String password;
  final int roleId;

  User({
    this.id,
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
}
