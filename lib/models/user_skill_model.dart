enum SkillLevel { beginner, intermediate, expert }

class UserSkillModel {
  final String id;
  final String userId;
  final String skillId;
  final String type;      // 'teach' or 'learn'
  final SkillLevel skillLevel;

  UserSkillModel({
    required this.id,
    required this.userId,
    required this.skillId,
    required this.type,
    required this.skillLevel,
  });

  factory UserSkillModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserSkillModel(
      id: id,
      userId: data['user_id'] ?? '',
      skillId: data['skill_id'] ?? '',
      type: data['type'] ?? 'learn',
      skillLevel: _stringToSkillLevel(data['skill_level'] ?? 'beginner'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'skill_id': skillId,
      'type': type,
      'skill_level': _skillLevelToString(skillLevel),
    };
  }

  static SkillLevel _stringToSkillLevel(String value) {
    switch (value) {
      case 'intermediate':
        return SkillLevel.intermediate;
      case 'expert':
        return SkillLevel.expert;
      default:
        return SkillLevel.beginner;
    }
  }

  static String _skillLevelToString(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return 'beginner';
      case SkillLevel.intermediate:
        return 'intermediate';
      case SkillLevel.expert:
        return 'expert';
    }
  }
}