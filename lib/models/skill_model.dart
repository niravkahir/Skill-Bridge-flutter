class SkillModel {
  final String id;
  final String name;
  final String category; // e.g., 'Programming', 'Design', 'Language'
  final String status;   // 'active' or 'inactive'

  SkillModel({
    required this.id,
    required this.name,
    required this.category,
    this.status = 'active',
  });

  factory SkillModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SkillModel(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'status': status,
    };
  }
}