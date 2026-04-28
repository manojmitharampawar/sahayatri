class FamilyGroup {
  final int id;
  final String name;
  final int ownerId;
  final DateTime createdAt;

  FamilyGroup({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
  });

  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    return FamilyGroup(
      id: json['id'] as int,
      name: json['name'] as String,
      ownerId: json['owner_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class FamilyMember {
  final int groupId;
  final int userId;
  final String role;

  FamilyMember({
    required this.groupId,
    required this.userId,
    required this.role,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      groupId: json['group_id'] as int,
      userId: json['user_id'] as int,
      role: json['role'] as String,
    );
  }
}
