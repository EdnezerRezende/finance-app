import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as app_notification;

/// Serviço para gerenciar notificações do sistema
class NotificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Carrega notificações do usuário atual
  static Future<List<app_notification.Notification>> loadNotifications({
    bool? onlyUnread,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryBuilder = _supabase
          .from('notifications')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id);

      final filteredQuery = onlyUnread == true 
          ? queryBuilder.eq('is_read', false)
          : queryBuilder;

      final orderedQuery = filteredQuery.order('created_at', ascending: false);

      final limitedQuery = limit != null 
          ? orderedQuery.limit(limit)
          : orderedQuery;

      final finalQuery = offset != null 
          ? limitedQuery.range(offset, offset + (limit ?? 20) - 1)
          : limitedQuery;

      final response = await finalQuery;
      
      return response
          .map((json) => app_notification.Notification.fromJson(json))
          .where((notification) => !notification.isExpired)
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar notificações: $e');
    }
  }

  /// Obtém a contagem de notificações não lidas
  static Future<int> getUnreadCount() async {
    try {
      final response = await _supabase.rpc('get_unread_notifications_count');
      return response as int? ?? 0;
    } catch (e) {
      // Fallback para contagem manual se a função RPC falhar
      try {
        final response = await _supabase
            .from('notifications')
            .select('id')
            .eq('user_id', _supabase.auth.currentUser!.id)
            .eq('is_read', false);
        
        return response.length;
      } catch (fallbackError) {
        throw Exception('Erro ao obter contagem de notificações: $fallbackError');
      }
    }
  }

  /// Marca uma notificação como lida
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      throw Exception('Erro ao marcar notificação como lida: $e');
    }
  }

  /// Marca múltiplas notificações como lidas
  static Future<void> markMultipleAsRead(List<String> notificationIds) async {
    try {
      final ids = notificationIds.map((id) => int.tryParse(id) ?? 0).toList();
      await _supabase.rpc('mark_notifications_as_read', params: {
        'notification_ids': ids,
      });
    } catch (e) {
      // Fallback para atualização individual
      for (final id in notificationIds) {
        try {
          await markAsRead(id);
        } catch (individualError) {
          // Continue com as outras notificações
          continue;
        }
      }
    }
  }

  /// Marca todas as notificações como lidas
  static Future<void> markAllAsRead() async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Erro ao marcar todas as notificações como lidas: $e');
    }
  }

  /// Deleta uma notificação
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      throw Exception('Erro ao deletar notificação: $e');
    }
  }


  /// Cria uma nova notificação
  static Future<app_notification.Notification> createNotification({
    required String userId,
    String? groupId,
    required app_notification.NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    DateTime? expiresAt,
  }) async {
    try {
      final notificationData = {
        'user_id': userId,
        'group_id': groupId,
        'type': type.value,
        'title': title,
        'message': message,
        'data': data,
        'expires_at': expiresAt?.toIso8601String(),
      };

      final response = await _supabase
          .from('notifications')
          .insert(notificationData)
          .select()
          .single();

      return app_notification.Notification.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao criar notificação: $e');
    }
  }

  /// Cria notificação de convite para grupo
  static Future<app_notification.Notification> createGroupInviteNotification({
    required String invitedUserId,
    required String groupId,
    required String groupName,
    required String inviterName,
  }) async {
    return await createNotification(
      userId: invitedUserId,
      groupId: groupId,
      type: app_notification.NotificationType.groupInvite,
      title: 'Convite para grupo',
      message: '$inviterName convidou você para participar do grupo "$groupName"',
      data: {
        'group_id': groupId,
        'group_name': groupName,
        'inviter_name': inviterName,
        'action_required': true,
      },
      expiresAt: DateTime.now().add(const Duration(days: 7)), // Expira em 7 dias
    );
  }

  /// Cria notificação de vencimento de despesa
  static Future<app_notification.Notification> createExpenseDueNotification({
    required String userId,
    required String expenseId,
    required String expenseDescription,
    required DateTime dueDate,
    required double amount,
  }) async {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    final dueDateFormatted = '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}';
    
    String message;
    if (daysUntilDue == 0) {
      message = 'A despesa "$expenseDescription" vence hoje ($dueDateFormatted)';
    } else if (daysUntilDue == 1) {
      message = 'A despesa "$expenseDescription" vence amanhã ($dueDateFormatted)';
    } else {
      message = 'A despesa "$expenseDescription" vence em $daysUntilDue dias ($dueDateFormatted)';
    }

    return await createNotification(
      userId: userId,
      type: app_notification.NotificationType.expenseDue,
      title: 'Despesa a vencer',
      message: message,
      data: {
        'expense_id': expenseId,
        'expense_description': expenseDescription,
        'due_date': dueDate.toIso8601String(),
        'amount': amount,
        'days_until_due': daysUntilDue,
      },
      expiresAt: dueDate.add(const Duration(days: 1)), // Expira 1 dia após o vencimento
    );
  }

  /// Cria notificação de vencimento de cartão de crédito
  static Future<app_notification.Notification> createCreditCardDueNotification({
    required String userId,
    required String cardId,
    required String cardName,
    required DateTime dueDate,
    required double amount,
  }) async {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    final dueDateFormatted = '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}';
    
    String message;
    if (daysUntilDue == 0) {
      message = 'A fatura do cartão "$cardName" vence hoje ($dueDateFormatted)';
    } else if (daysUntilDue == 1) {
      message = 'A fatura do cartão "$cardName" vence amanhã ($dueDateFormatted)';
    } else {
      message = 'A fatura do cartão "$cardName" vence em $daysUntilDue dias ($dueDateFormatted)';
    }

    return await createNotification(
      userId: userId,
      type: app_notification.NotificationType.creditCardDue,
      title: 'Fatura de cartão a vencer',
      message: message,
      data: {
        'card_id': cardId,
        'card_name': cardName,
        'due_date': dueDate.toIso8601String(),
        'amount': amount,
        'days_until_due': daysUntilDue,
      },
      expiresAt: dueDate.add(const Duration(days: 3)), // Expira 3 dias após o vencimento
    );
  }

  /// Limpa notificações expiradas
  static Future<int> cleanExpiredNotifications() async {
    try {
      final response = await _supabase.rpc('clean_expired_notifications');
      return response as int? ?? 0;
    } catch (e) {
      throw Exception('Erro ao limpar notificações expiradas: $e');
    }
  }

  /// Verifica se há notificações de vencimento que precisam ser criadas
  static Future<void> checkAndCreateDueNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowStart = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      final tomorrowEnd = tomorrowStart.add(const Duration(days: 1));

      // Verificar despesas que vencem amanhã
      // TODO: Implementar quando tivermos o modelo de despesas com data de vencimento
      
      // Verificar cartões de crédito que vencem amanhã
      // TODO: Implementar verificação de vencimento de cartões
      
      // Verificar financiamentos que vencem amanhã
      // TODO: Implementar verificação de vencimento de financiamentos

    } catch (e) {
      throw Exception('Erro ao verificar vencimentos: $e');
    }
  }

  /// Subscreve a mudanças em tempo real nas notificações
  static RealtimeChannel subscribeToNotifications({
    required Function(app_notification.Notification) onNotificationReceived,
    required Function(String) onNotificationUpdated,
    required Function(String) onNotificationDeleted,
  }) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuário não autenticado');
    }

    return _supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final notification = app_notification.Notification.fromJson(payload.newRecord);
              onNotificationReceived(notification);
            } catch (e) {
              // Ignorar erros de parsing
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final notificationId = payload.newRecord['id'].toString();
            onNotificationUpdated(notificationId);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final notificationId = payload.oldRecord['id'].toString();
            onNotificationDeleted(notificationId);
          },
        )
        .subscribe();
  }
}
