/// Model untuk merepresentasikan satu user dari API reqres.in.
class UserModel {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String avatar;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatar,
  });

  /// Gabungan firstName dan lastName.
  String get fullName => '$firstName $lastName';

  /// Parse JSON dari endpoint /users, null-safe.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: (json['email'] as String?) ?? '',
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      avatar: (json['avatar'] as String?) ?? '',
    );
  }

  /// Salin model dengan field yang diubah (untuk update lokal).
  UserModel copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? avatar,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, email: $email, fullName: $fullName)';
}
