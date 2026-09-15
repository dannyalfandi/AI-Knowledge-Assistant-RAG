import 'dart:convert';

import '../../domain/entities/user.dart';

/// Transport/storage representation of [User].
///
/// Two backend shapes feed this model:
///  - `POST /api/auth/login` returns the full `{ id, email, name, role }`.
///  - `GET  /api/auth/me` returns only `{ id, role }` — `email`/`name` fall back
///    to empty strings and are re-filled from the cached login payload.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String,
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
      };

  String encode() => jsonEncode(toJson());

  static UserModel? tryDecode(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
