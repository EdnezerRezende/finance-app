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
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

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
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from Supabase data
  factory CreditCard.fromSupabase(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'],
      name: json['card_name'],
      cardNumberMasked: json['card_number_masked'] ?? '**** **** **** ****',
      bankName: json['bank_name'] ?? '',
      cardType: json['card_type'] ?? 'credit',
      creditLimit: (json['credit_limit'] ?? 0.0).toDouble(),
      availableLimit: (json['available_limit'] ?? 0.0).toDouble(),
      currentBalance: (json['current_balance'] ?? 0.0).toDouble(),
      closingDay: json['closing_day'] ?? 1,
      dueDay: json['due_day'] ?? 10,
      isActive: json['is_active'] ?? true,
      cardColor: json['card_color'] ?? '#2196F3',
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