class CreditCardMaster {
  final String id;
  final String name;
  final String cardNumberMasked;
  final String bankName;
  final String cardType;
  final double creditLimit;
  final int closingDay;
  final int dueDay;
  final bool isActive;
  final String cardColor;
  final String? groupId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CreditCardMaster({
    required this.id,
    required this.name,
    required this.cardNumberMasked,
    required this.bankName,
    this.cardType = 'credit',
    this.creditLimit = 0.0,
    required this.closingDay,
    required this.dueDay,
    this.isActive = true,
    this.cardColor = '#2196F3',
    this.groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert to Supabase format
  Map<String, dynamic> toSupabase({bool includeId = false}) {
    final data = {
      'name': name,
      'card_number_masked': cardNumberMasked,
      'bank_name': bankName,
      'card_type': cardType,
      'credit_limit': creditLimit,
      'closing_day': closingDay,
      'due_day': dueDay,
      'is_active': isActive,
      'card_color': cardColor,
      'group_id': groupId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    if (includeId) {
      data['id'] = id;
    }
    
    return data;
  }

  // Create from Supabase data
  factory CreditCardMaster.fromSupabase(Map<String, dynamic> json) {
    return CreditCardMaster(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      cardNumberMasked: json['card_number_masked']?.toString() ?? '**** **** **** ****',
      bankName: json['bank_name']?.toString() ?? '',
      cardType: json['card_type']?.toString() ?? 'credit',
      creditLimit: _parseDoubleValue(json['credit_limit']),
      closingDay: _parseIntValue(json['closing_day'], 1),
      dueDay: _parseIntValue(json['due_day'], 10),
      isActive: json['is_active'] ?? true,
      cardColor: json['card_color']?.toString() ?? '#2196F3',
      groupId: json['group_id']?.toString(),
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

  // Create a copy with updated fields
  CreditCardMaster copyWith({
    String? id,
    String? name,
    String? cardNumberMasked,
    String? bankName,
    String? cardType,
    double? creditLimit,
    int? closingDay,
    int? dueDay,
    bool? isActive,
    String? cardColor,
    String? groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditCardMaster(
      id: id ?? this.id,
      name: name ?? this.name,
      cardNumberMasked: cardNumberMasked ?? this.cardNumberMasked,
      bankName: bankName ?? this.bankName,
      cardType: cardType ?? this.cardType,
      creditLimit: creditLimit ?? this.creditLimit,
      closingDay: closingDay ?? this.closingDay,
      dueDay: dueDay ?? this.dueDay,
      isActive: isActive ?? this.isActive,
      cardColor: cardColor ?? this.cardColor,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CreditCardMaster(id: $id, name: $name, bankName: $bankName, cardNumberMasked: $cardNumberMasked)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditCardMaster && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
