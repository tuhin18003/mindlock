class ChallengeModel {
  final int id;
  final String title;
  final String description;
  final String type;
  final String difficulty;
  final int rewardMinutes;
  final int durationSeconds;
  final bool isPro;
  final bool isActive;
  final Map<String, dynamic>? content;
  final String? categoryName;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.rewardMinutes,
    required this.durationSeconds,
    required this.isPro,
    required this.isActive,
    this.content,
    this.categoryName,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'reflection',
      difficulty: json['difficulty'] as String? ?? 'easy',
      rewardMinutes: json['reward_minutes'] as int? ?? 5,
      durationSeconds: json['duration_seconds'] as int? ?? 60,
      isPro: json['is_pro'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      content: json['content'] as Map<String, dynamic>?,
      categoryName: json['category_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type,
    'difficulty': difficulty,
    'reward_minutes': rewardMinutes,
    'duration_seconds': durationSeconds,
    'is_pro': isPro,
    'is_active': isActive,
    'content': content,
    'category_name': categoryName,
  };
}
