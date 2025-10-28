class CreditCardTransaction {
  final String id;
  final String creditCardId;
  final String description;
  final double amount;
  final DateTime transactionDate;
  final int referenceMonth;
  final int referenceYear;
  final bool isPayment;
  final String? groupId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CreditCardTransaction({
    required this.id,
    required this.creditCardId,
    required this.description,
    required this.amount,
    required this.transactionDate,
    required this.referenceMonth,
    required this.referenceYear,
    this.isPayment = false,
    this.groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Computed properties
  double get absoluteAmount => amount.abs();
  bool get isCredit => amount < 0;
  bool get isDebit => amount > 0;
  String get referenceKey => '${referenceMonth.toString().padLeft(2, '0')}/$referenceYear';

  // Convert to Supabase format
  Map<String, dynamic> toSupabase({bool includeId = false}) {
    final data = {
      'credit_card_id': creditCardId,
      'description': description,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'reference_month': referenceMonth,
      'reference_year': referenceYear,
      'is_payment': isPayment,
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
  factory CreditCardTransaction.fromSupabase(Map<String, dynamic> json) {
    return CreditCardTransaction(
      id: json['id']?.toString() ?? '',
      creditCardId: json['credit_card_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      amount: _parseDoubleValue(json['amount']),
      transactionDate: DateTime.parse(json['transaction_date'] ?? DateTime.now().toIso8601String()),
      referenceMonth: _parseIntValue(json['reference_month'], DateTime.now().month),
      referenceYear: _parseIntValue(json['reference_year'], DateTime.now().year),
      isPayment: json['is_payment'] ?? false,
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
  CreditCardTransaction copyWith({
    String? id,
    String? creditCardId,
    String? description,
    double? amount,
    DateTime? transactionDate,
    int? referenceMonth,
    int? referenceYear,
    bool? isPayment,
    String? groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditCardTransaction(
      id: id ?? this.id,
      creditCardId: creditCardId ?? this.creditCardId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      referenceMonth: referenceMonth ?? this.referenceMonth,
      referenceYear: referenceYear ?? this.referenceYear,
      isPayment: isPayment ?? this.isPayment,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CreditCardTransaction(id: $id, description: $description, amount: $amount, referenceKey: $referenceKey)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditCardTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
