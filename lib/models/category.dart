class Category {
  final int id;
  final String categoria;
  final String type;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.categoria,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'categoria': categoria,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create from Supabase data
  factory Category.fromSupabase(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      categoria: json['categoria'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Category copyWith({
    String? categoria,
    String? type,
  }) {
    return Category(
      id: id,
      categoria: categoria ?? this.categoria,
      type: type ?? this.type,
      createdAt: createdAt,
    );
  }

  // Helper getters for compatibility
  String get name => categoria;
  String get displayName => categoria;
  String get color => '#757575'; // Default color
  String get icon => 'category'; // Default icon
}
