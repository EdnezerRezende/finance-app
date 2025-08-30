enum TransactionType {
  DESPESA,
  ENTRADA,
}

enum TransactionCategory {
  food,
  transport,
  entertainment,
  health,
  education,
  shopping,
  bills,
  salary,
  investment,
  other,
}

class Transaction {
  final int id;
  final String type;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final bool isPago;
  final String userId;
  final String? groupId;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    this.isPago = false,
    required this.userId,
    this.groupId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    final data = <String, dynamic>{
      'type': type,
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'isPago': isPago,
      'userId': userId,
      'group_id': groupId,
    };
    
    // Só incluir id se não for 0 (novo registro)
    if (id != 0) {
      data['id'] = id;
    }
    
    // Só incluir created_at se existir
    if (createdAt != null) {
      data['created_at'] = createdAt!.toIso8601String();
    }
    
    return data;
  }

  // Convert to Supabase format with encryption
  Map<String, dynamic> toSupabaseEncrypted(
    String Function(String) encryptField,
    String Function(double) encryptNumericField,
  ) {
    final data = <String, dynamic>{
      'type': type,
      'amount': encryptNumericField(amount), // Criptografar valor como TEXT
      'description': encryptField(description), // Criptografar descrição
      'category': category,
      'date': date.toIso8601String(),
      'isPago': isPago,
      'userId': userId,
      'group_id': groupId,
    };
    
    // Só incluir id se não for 0 (novo registro)
    if (id != 0) {
      data['id'] = id;
    }
    
    // Só incluir created_at se existir
    if (createdAt != null) {
      data['created_at'] = createdAt!.toIso8601String();
    }
    
    return data;
  }

  // Create from Supabase data (expense table)
  factory Transaction.fromSupabase(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'] ?? 'expense',
      amount: (json['amount'] ?? 0.0).toDouble(),
      description: json['description'] ?? 'Transação',
      category: json['category'] ?? 'Outros',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      isPago: json['isPago'] ?? false,
      userId: json['userId'] ?? '',
      groupId: json['group_id'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Cria Transaction a partir de dados do Supabase com descriptografia
  factory Transaction.fromSupabaseEncrypted(
    Map<String, dynamic> json,
    String Function(String) decryptField,
    double Function(String) decryptNumericField,
  ) {
    return Transaction(
      id: json['id'],
      type: json['type'] ?? 'expense',
      amount: decryptNumericField(json['amount']), // Descriptografar valor
      description: decryptField(json['description']), // Descriptografar descrição
      category: json['category'] ?? 'Outros',
      date: DateTime.parse(json['date']),
      isPago: json['isPago'] ?? false,
      userId: json['userId'],
      groupId: json['group_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  // Helper getters for compatibility
  String get title => description;
  String get categoryName => category;
  String get categoryId => category;
  TransactionType get transactionType => (type == 'income' || type == 'ENTRADA') ? TransactionType.ENTRADA : TransactionType.DESPESA;
  bool get isExpense => type == 'expense' || type == 'DESPESA';
  bool get isIncome => type == 'income' || type == 'ENTRADA';
  
  // Legacy support for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'isPago': isPago,
      'userId': userId,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'] ?? 'expense',
      amount: json['amount'].toDouble(),
      description: json['description'] ?? 'Transação',
      category: json['category'] ?? 'Outros',
      date: DateTime.parse(json['date']),
      isPago: json['isPago'] ?? false,
      userId: json['userId'] ?? '',
    );
  }

  Transaction copyWith({
    String? type,
    double? amount,
    String? description,
    String? category,
    DateTime? date,
    bool? isPago,
    String? userId,
    String? groupId,
  }) {
    return Transaction(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      isPago: isPago ?? this.isPago,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt,
    );
  }

  // Helper method to get category display name
  String get categoryDisplayName => category;
}