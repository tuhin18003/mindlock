class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String timezone;
  final String status;
  final bool emailVerified;
  final String? lastActiveAt;
  final String? createdAt;
  final int currentStreak;
  final int longestStreak;
  final String tier; // 'free' or 'pro'

  const UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.timezone,
    required this.status,
    required this.emailVerified,
    this.lastActiveAt,
    this.createdAt,
    required this.currentStreak,
    required this.longestStreak,
    required this.tier,
  });

  bool get isPro => tier == 'pro';

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatar: json['avatar'] as String?,
      timezone: json['timezone'] as String? ?? 'UTC',
      status: json['status'] as String? ?? 'active',
      emailVerified: json['email_verified'] as bool? ?? false,
      lastActiveAt: json['last_active_at'] as String?,
      createdAt: json['created_at'] as String?,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      tier: json['tier'] as String? ?? 'free',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar': avatar,
    'timezone': timezone,
    'status': status,
    'email_verified': emailVerified,
    'last_active_at': lastActiveAt,
    'created_at': createdAt,
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
    'tier': tier,
  };

  UserProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    String? timezone,
    String? status,
    bool? emailVerified,
    String? lastActiveAt,
    String? createdAt,
    int? currentStreak,
    int? longestStreak,
    String? tier,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      timezone: timezone ?? this.timezone,
      status: status ?? this.status,
      emailVerified: emailVerified ?? this.emailVerified,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      createdAt: createdAt ?? this.createdAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      tier: tier ?? this.tier,
    );
  }
}
