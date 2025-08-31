/// Modelo para notificações do sistema
class Notification {
  final String id;
  final String userId;
  final String? groupId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const Notification({
    required this.id,
    required this.userId,
    this.groupId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.expiresAt,
  });

  /// Cria uma notificação a partir dos dados do Supabase
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      groupId: json['group_id']?.toString(),
      type: NotificationType.fromString(json['type']),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at']) 
          : null,
    );
  }

  /// Converte a notificação para JSON para envio ao Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'group_id': groupId,
      'type': type.value,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  /// Cria uma cópia da notificação com campos alterados
  Notification copyWith({
    String? id,
    String? userId,
    String? groupId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Verifica se a notificação está expirada
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Obtém o ícone apropriado para o tipo de notificação
  String get icon {
    switch (type) {
      case NotificationType.groupInvite:
        return '👥';
      case NotificationType.expenseDue:
        return '⏰';
      case NotificationType.creditCardDue:
        return '💳';
      case NotificationType.budgetAlert:
        return '📊';
      case NotificationType.financeDue:
        return '🏦';
      case NotificationType.general:
        return '📢';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Notification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Notification{id: $id, type: $type, title: $title, isRead: $isRead}';
  }
}

/// Tipos de notificação disponíveis no sistema
enum NotificationType {
  groupInvite('group_invite'),
  expenseDue('expense_due'),
  creditCardDue('credit_card_due'),
  budgetAlert('budget_alert'),
  financeDue('finance_due'),
  general('general');

  const NotificationType(this.value);
  final String value;

  /// Cria um NotificationType a partir de uma string
  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.general,
    );
  }

  /// Obtém a descrição legível do tipo
  String get description {
    switch (this) {
      case NotificationType.groupInvite:
        return 'Convite para grupo';
      case NotificationType.expenseDue:
        return 'Despesa a vencer';
      case NotificationType.creditCardDue:
        return 'Cartão a vencer';
      case NotificationType.budgetAlert:
        return 'Alerta de orçamento';
      case NotificationType.financeDue:
        return 'Financiamento a vencer';
      case NotificationType.general:
        return 'Notificação geral';
    }
  }
}
