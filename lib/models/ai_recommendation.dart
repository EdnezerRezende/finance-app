import 'package:uuid/uuid.dart';

enum RecommendationType {
  expenseReduction,
  investment,
  budgetOptimization,
  creditCardAdvice,
  savings,
}

class AIRecommendation {
  final String id;
  final String title;
  final String description;
  final RecommendationType type;
  final double potentialSavings;
  final List<String> actions;
  final DateTime createdAt;
  final bool isRead;

  AIRecommendation({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    required this.potentialSavings,
    required this.actions,
    required this.createdAt,
    this.isRead = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'potentialSavings': potentialSavings,
      'actions': actions,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: RecommendationType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      potentialSavings: json['potentialSavings'].toDouble(),
      actions: List<String>.from(json['actions']),
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
    );
  }

  AIRecommendation copyWith({
    String? title,
    String? description,
    RecommendationType? type,
    double? potentialSavings,
    List<String>? actions,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AIRecommendation(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      potentialSavings: potentialSavings ?? this.potentialSavings,
      actions: actions ?? this.actions,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
} 