class Group {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int memberCount;
  final bool isOwner;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount = 0,
    this.isOwner = false,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      memberCount: json['member_count'] ?? 0,
      isOwner: json['is_owner'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberCount,
    bool? isOwner,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberCount: memberCount ?? this.memberCount,
      isOwner: isOwner ?? this.isOwner,
    );
  }
}
