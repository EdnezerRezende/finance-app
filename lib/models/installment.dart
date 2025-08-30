class Installment {
  final String id;
  final double valor;
  final int parcelas;
  final int parcelasPagas;
  final String descricao;
  final int mes;
  final int ano;
  final String traceControl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields for compatibility
  final String status;

  Installment({
    required this.id,
    required this.valor,
    required this.parcelas,
    required this.parcelasPagas,
    required this.descricao,
    required this.mes,
    required this.ano,
    String? traceControll,
    String? traceControl,
    this.status = 'pending',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : traceControl = traceControll ?? traceControl ?? '',
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isPaid => parcelasPagas == parcelas;
  bool get isPending => parcelasPagas < parcelas;
  
  // Convert to Supabase format
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'valor': valor,
      'parcelas': parcelas,
      'parcelasPagas': parcelasPagas,
      'Descricao': descricao,
      'mes': mes,
      'ano': ano,
      'traceControll': traceControl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from Supabase data
  factory Installment.fromSupabase(Map<String, dynamic> json) {
    return Installment(
      id: json['id'].toString(),
      valor: _parseDoubleValue(json['valor']),
      parcelas: json['parcelas'] ?? 1,
      parcelasPagas: json['parcelasPagas'] ?? 0,
      descricao: json['Descricao'] ?? '',
      mes: json['mes'] ?? DateTime.now().month,
      ano: json['ano'] ?? DateTime.now().year,
      traceControll: json['traceControll'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Helper method to safely parse double values
  static double _parseDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Installment copyWith({
    double? valor,
    int? parcelas,
    int? parcelasPagas,
    String? descricao,
    int? mes,
    int? ano,
    String? traceControl,
    String? status,
  }) {
    return Installment(
      id: id,
      valor: valor ?? this.valor,
      parcelas: parcelas ?? this.parcelas,
      parcelasPagas: parcelasPagas ?? this.parcelasPagas,
      descricao: descricao ?? this.descricao,
      mes: mes ?? this.mes,
      ano: ano ?? this.ano,
      traceControll: traceControl ?? this.traceControl,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get displayTitle {
    return '$descricao ($parcelasPagas/$parcelas)';
  }

  String get displaySubtitle {
    return '$mes/$ano';
  }
}
