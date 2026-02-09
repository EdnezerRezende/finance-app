class CreditCard {
  final String id;
  final String name;
  final String cardNumberMasked;
  final String bankName;
  final String cardType;
  final double creditLimit;
  final double availableLimit;
  final double currentBalance;
  final int closingDay;
  final int dueDay;
  final bool isActive;
  final String cardColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? groupId;
  final int mes;
  final int ano;

  CreditCard({
    required this.id,
    required this.name,
    required this.cardNumberMasked,
    required this.bankName,
    this.cardType = 'credit',
    required this.creditLimit,
    required this.availableLimit,
    required this.currentBalance,
    required this.closingDay,
    required this.dueDay,
    this.isActive = true,
    this.cardColor = '#2196F3',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.groupId,
    int? mes,
    int? ano,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       mes = mes ?? DateTime.now().month,
       ano = ano ?? DateTime.now().year;

  double get usagePercentage => creditLimit > 0 ? (currentBalance / creditLimit) * 100 : 0;
  
  // Legacy compatibility getters
  String get cardName => name;
  String get cardNumber => cardNumberMasked;
  String get bank => bankName;
  String get color => cardColor;
  double get limit => creditLimit;
  
  // Date getters for compatibility
  DateTime get dueDate => DateTime(DateTime.now().year, DateTime.now().month, dueDay);
  DateTime get closingDate => DateTime(DateTime.now().year, DateTime.now().month, closingDay);

  // Convert to Supabase format
  Map<String, dynamic> toSupabase({bool includeId = false}) {
    final data = {
      'card_name': name,
      'card_number_masked': cardNumberMasked,
      'bank_name': bankName,
      'card_type': cardType,
      'credit_limit': creditLimit,
      'available_limit': availableLimit,
      'current_balance': currentBalance,
      'closing_day': closingDay,
      'due_day': dueDay,
      'is_active': isActive,
      'card_color': cardColor,
      'group_id': groupId,
      'mes': mes,
      'ano': ano,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    if (includeId) {
      data['id'] = id;
    }
    
    return data;
  }

  /// Converte para Map do Supabase com campos criptografados
  Map<String, dynamic> toSupabaseEncrypted(
    String Function(String) encryptField,
    String Function(double) encryptNumericField,
    {bool includeId = false}
  ) {
    final data = {
      'card_name': encryptField(name), // Criptografar nome do cartão
      'card_number_masked': cardNumberMasked, // Manter mascarado (não sensível)
      'bank_name': bankName, // Manter banco (não sensível)
      'card_type': cardType,
      'credit_limit': encryptNumericField(creditLimit), // Criptografar limite
      'available_limit': encryptNumericField(availableLimit), // Criptografar limite disponível
      'current_balance': encryptNumericField(currentBalance), // Criptografar saldo atual
      'closing_day': closingDay,
      'due_day': dueDay,
      'is_active': isActive,
      'card_color': cardColor,
      'group_id': groupId,
      'mes': mes,
      'ano': ano,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    if (includeId) {
      data['id'] = id;
    }
    
    return data;
  }

  // Create from Supabase data
  factory CreditCard.fromSupabase(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id']?.toString() ?? '',
      name: json['card_name']?.toString() ?? '',
      cardNumberMasked: json['card_number_masked']?.toString() ?? '**** **** **** ****',
      bankName: json['bank_name']?.toString() ?? '',
      cardType: json['card_type']?.toString() ?? 'credit',
      creditLimit: _parseDoubleValue(json['credit_limit']),
      availableLimit: _parseDoubleValue(json['available_limit']),
      currentBalance: _parseDoubleValue(json['current_balance']),
      closingDay: _parseIntValue(json['closing_day'], 1),
      dueDay: _parseIntValue(json['due_day'], 10),
      isActive: json['is_active'] ?? true,
      cardColor: json['card_color']?.toString() ?? '#2196F3',
      groupId: json['group_id']?.toString(),
      mes: _parseIntValue(json['mes'], DateTime.now().month),
      ano: _parseIntValue(json['ano'], DateTime.now().year),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Helper methods to safely parse values
  static double _parseDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseIntValue(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Cria CreditCard a partir de dados do Supabase com descriptografia
  factory CreditCard.fromSupabaseEncrypted(
    Map<String, dynamic> json,
    String Function(String) decryptField,
    double Function(String) decryptNumericField,
  ) {
    return CreditCard(
      id: json['id']?.toString() ?? '',
      name: decryptField(json['card_name']?.toString() ?? ''), // Descriptografar nome
      cardNumberMasked: json['card_number_masked']?.toString() ?? '**** **** **** ****',
      bankName: json['bank_name']?.toString() ?? '',
      cardType: json['card_type']?.toString() ?? 'credit',
      creditLimit: decryptNumericField(json['credit_limit']?.toString() ?? '0'), // Descriptografar limite
      availableLimit: decryptNumericField(json['available_limit']?.toString() ?? '0'), // Descriptografar limite disponível
      currentBalance: decryptNumericField(json['current_balance']?.toString() ?? '0'), // Descriptografar saldo
      closingDay: _parseIntValue(json['closing_day'], 1),
      dueDay: _parseIntValue(json['due_day'], 10),
      isActive: json['is_active'] ?? true,
      cardColor: json['card_color']?.toString() ?? '#2196F3',
      groupId: json['group_id']?.toString(),
      mes: _parseIntValue(json['mes'], DateTime.now().month),
      ano: _parseIntValue(json['ano'], DateTime.now().year),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Legacy support for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cardNumber': cardNumberMasked,
      'limit': creditLimit,
      'currentBalance': currentBalance,
      'dueDate': DateTime(DateTime.now().year, DateTime.now().month, dueDay).toIso8601String(),
      'closingDate': DateTime(DateTime.now().year, DateTime.now().month, closingDay).toIso8601String(),
      'bank': bankName,
      'color': cardColor,
    };
  }

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'],
      name: json['name'],
      cardNumberMasked: json['cardNumber'],
      bankName: json['bank'],
      creditLimit: json['limit'].toDouble(),
      availableLimit: json['limit'].toDouble() - json['currentBalance'].toDouble(),
      currentBalance: json['currentBalance'].toDouble(),
      closingDay: DateTime.parse(json['closingDate']).day,
      dueDay: DateTime.parse(json['dueDate']).day,
      cardColor: json['color'],
    );
  }

  CreditCard copyWith({
    String? name,
    String? cardNumberMasked,
    String? bankName,
    String? cardType,
    double? creditLimit,
    double? availableLimit,
    double? currentBalance,
    int? closingDay,
    int? dueDay,
    bool? isActive,
    String? cardColor,
  }) {
    return CreditCard(
      id: id,
      name: name ?? this.name,
      cardNumberMasked: cardNumberMasked ?? this.cardNumberMasked,
      bankName: bankName ?? this.bankName,
      cardType: cardType ?? this.cardType,
      creditLimit: creditLimit ?? this.creditLimit,
      availableLimit: availableLimit ?? this.availableLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      closingDay: closingDay ?? this.closingDay,
      dueDay: dueDay ?? this.dueDay,
      isActive: isActive ?? this.isActive,
      cardColor: cardColor ?? this.cardColor,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}