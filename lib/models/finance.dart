class Finance {
  final int id;
  final DateTime createdAt;
  final String tipo;
  final double? valorTotal;
  final double? saldoDevedor;
  final int? quantidadeParcelas;
  final List<int>? parcelasQuitadas;
  final double? valorDesconto;
  final double? valorPago;
  final String? userId;
  final String? groupId;

  Finance({
    required this.id,
    required this.createdAt,
    required this.tipo,
    this.valorTotal,
    this.saldoDevedor,
    this.quantidadeParcelas,
    this.parcelasQuitadas,
    this.valorDesconto,
    this.valorPago,
    this.userId,
    this.groupId,
  });

  factory Finance.fromSupabase(Map<String, dynamic> json) {
    return Finance(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      tipo: json['tipo'] as String,
      valorTotal: json['valorTotal'] != null ? (json['valorTotal'] as num).toDouble() : null,
      saldoDevedor: json['saldoDevedor'] != null ? (json['saldoDevedor'] as num).toDouble() : null,
      quantidadeParcelas: json['quantidadeParcelas'] as int?,
      parcelasQuitadas: json['parcelasQuitadas'] != null 
          ? List<int>.from(json['parcelasQuitadas'] as List) 
          : null,
      valorDesconto: json['valorDesconto'] != null ? (json['valorDesconto'] as num).toDouble() : null,
      valorPago: json['valorPago'] != null ? (json['valorPago'] as num).toDouble() : null,
      userId: json['userId'] as String?,
      groupId: json['group_id'] as String?,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'tipo': tipo,
      'valorTotal': valorTotal,
      'saldoDevedor': saldoDevedor,
      'quantidadeParcelas': quantidadeParcelas,
      'parcelasQuitadas': parcelasQuitadas,
      'valorDesconto': valorDesconto,
      'valorPago': valorPago,
      'userId': userId,
      'group_id': groupId,
    };
  }

  // Getters úteis
  int get parcelasPagas => parcelasQuitadas?.length ?? 0;
  
  int get parcelasRestantes => (quantidadeParcelas ?? 0) - parcelasPagas;
  
  double get percentualPago {
    if (quantidadeParcelas == null || quantidadeParcelas == 0) return 0.0;
    return (parcelasPagas / quantidadeParcelas!) * 100;
  }

  bool get isQuitado => parcelasRestantes == 0;

  Finance copyWith({
    int? id,
    DateTime? createdAt,
    String? tipo,
    double? valorTotal,
    double? saldoDevedor,
    int? quantidadeParcelas,
    List<int>? parcelasQuitadas,
    double? valorDesconto,
    double? valorPago,
    String? userId,
    String? groupId,
  }) {
    return Finance(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      tipo: tipo ?? this.tipo,
      valorTotal: valorTotal ?? this.valorTotal,
      saldoDevedor: saldoDevedor ?? this.saldoDevedor,
      quantidadeParcelas: quantidadeParcelas ?? this.quantidadeParcelas,
      parcelasQuitadas: parcelasQuitadas ?? this.parcelasQuitadas,
      valorDesconto: valorDesconto ?? this.valorDesconto,
      valorPago: valorPago ?? this.valorPago,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
    );
  }
}

enum FinanceType {
  consorcio('Consórcio'),
  emprestimo('Empréstimo'),
  financiamento('Financiamento');

  const FinanceType(this.displayName);
  final String displayName;

  static FinanceType fromString(String value) {
    return FinanceType.values.firstWhere(
      (type) => type.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => FinanceType.financiamento,
    );
  }
}
