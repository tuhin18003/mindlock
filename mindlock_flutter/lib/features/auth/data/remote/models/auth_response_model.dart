class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String status;
  final String timezone;
  final String locale;
  final bool emailVerified;
  final String? lastActiveAt;
  final String createdAt;
  final List<String> roles;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.status,
    required this.timezone,
    required this.locale,
    required this.emailVerified,
    this.lastActiveAt,
    required this.createdAt,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatar: json['avatar'] as String?,
      status: json['status'] as String? ?? 'active',
      timezone: json['timezone'] as String? ?? 'UTC',
      locale: json['locale'] as String? ?? 'en',
      emailVerified: json['email_verified'] as bool? ?? false,
      lastActiveAt: json['last_active_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'status': status,
      'timezone': timezone,
      'locale': locale,
      'email_verified': emailVerified,
      'last_active_at': lastActiveAt,
      'created_at': createdAt,
      'roles': roles,
    };
  }
}

class AuthResponse {
  final String token;
  final UserModel user;

  const AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Support both { token, user } and { data: { token, user } }
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AuthResponse(
      token: data['token'] as String? ?? data['access_token'] as String? ?? '',
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}
