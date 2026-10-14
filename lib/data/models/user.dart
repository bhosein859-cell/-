import 'dart:convert';

import 'model_utils.dart';

/// نقش‌های کاربری در گره‌گشا.
class UserRole {
  UserRole._();

  static const String admin = 'admin';
  static const String manager = 'manager';
  static const String member = 'member';

  static const Map<String, String> faLabels = {
    admin: 'مدیر',
    manager: 'راهبر',
    member: 'عضو',
  };
}

/// مدل کاربر.
class User {
  const User({
    this.id,
    required this.username,
    required this.fullName,
    this.role = UserRole.member,
    this.avatarPath,
    this.passwordHash,
    this.salt,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  final int? id;
  final String username;
  final String fullName;
  final String role;
  final String? avatarPath;
  final String? passwordHash;
  final String? salt;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  String get roleFa => UserRole.faLabels[role] ?? role;

  factory User.fromMap(Map<String, dynamic> m) => User(
        id: m['id'] as int?,
        username: m['username'] as String,
        fullName: m['full_name'] as String,
        role: m['role'] as String? ?? UserRole.member,
        avatarPath: m['avatar_path'] as String?,
        passwordHash: m['password_hash'] as String?,
        salt: m['salt'] as String?,
        isActive: (m['is_active'] as int?) == 1,
        createdAt: parseDbDate(m['created_at']),
        updatedAt: parseDbDate(m['updated_at']),
        metadata: decodeJsonMap(m['metadata']),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'username': username,
        'full_name': fullName,
        'role': role,
        'avatar_path': avatarPath,
        'password_hash': passwordHash,
        'salt': salt,
        'is_active': isActive ? 1 : 0,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        'metadata': jsonEncode(metadata),
      };

  User copyWith({
    String? fullName,
    String? role,
    String? avatarPath,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) =>
      User(
        id: id,
        username: username,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        avatarPath: avatarPath ?? this.avatarPath,
        passwordHash: passwordHash,
        salt: salt,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        metadata: metadata ?? this.metadata,
      );
}
