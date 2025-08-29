class Purchase {
  final String id;
  final String creditCardId;
  final String description;
  final double totalAmount;
  final int installmentsCount;
  final double installmentAmount;
  final String? category;
  final String? merchantName;
  final String? location;
  final DateTime purchaseDate;
  final DateTime firstInstallmentDate;
  final String status; // active, cancelled, completed
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Purchase({
    required this.id,
    required this.creditCardId,
    required this.description,
    required this.totalAmount,
    required this.installmentsCount,
    required this.installmentAmount,
    this.category,
    this.merchantName,
    this.location,
    required this.purchaseDate,
    required this.firstInstallmentDate,
    this.status = 'active',
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'credit_card_id': creditCardId,
      'description': description,
      'total_amount': totalAmount,
      'installments_count': installmentsCount,
      'installment_amount': installmentAmount,
      'category': category,
      'merchant_name': merchantName,
      'location': location,
      'purchase_date': purchaseDate.toIso8601String().split('T')[0], // Date only
      'first_installment_date': firstInstallmentDate.toIso8601String().split('T')[0],
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from Supabase data
  factory Purchase.fromSupabase(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      creditCardId: json['credit_card_id'],
      description: json['description'],
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      installmentsCount: json['installments_count'] ?? 1,
      installmentAmount: (json['installment_amount'] ?? 0.0).toDouble(),
      category: json['category'],
      merchantName: json['merchant_name'],
      location: json['location'],
      purchaseDate: DateTime.parse(json['purchase_date']),
      firstInstallmentDate: DateTime.parse(json['first_installment_date']),
      status: json['status'] ?? 'active',
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Purchase copyWith({
    String? description,
    double? totalAmount,
    int? installmentsCount,
    double? installmentAmount,
    String? category,
    String? merchantName,
    String? location,
    DateTime? purchaseDate,
    DateTime? firstInstallmentDate,
    String? status,
    String? notes,
  }) {
    return Purchase(
      id: id,
      creditCardId: creditCardId,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      installmentsCount: installmentsCount ?? this.installmentsCount,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      category: category ?? this.category,
      merchantName: merchantName ?? this.merchantName,
      location: location ?? this.location,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      firstInstallmentDate: firstInstallmentDate ?? this.firstInstallmentDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
