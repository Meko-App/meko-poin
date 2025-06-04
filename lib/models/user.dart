class User {
  final int id;
  final String name;
  final String email;
  final int roleId;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.roleId,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      roleId: map['role_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role_id': roleId,
    };
  }
}
