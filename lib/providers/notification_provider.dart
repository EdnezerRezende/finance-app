import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as app_notification;
import '../services/notification_service.dart';

/// Provider para gerenciar o estado das notificações
class NotificationProvider with ChangeNotifier {
  List<app_notification.Notification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _realtimeSubscription;

  /// Limpa todas as notificações e dados do provider
  void clearData() {
    _notifications.clear();
    _unreadCount = 0;
    _error = null;
    _isLoading = false;
    _realtimeSubscription?.unsubscribe();
    _realtimeSubscription = null;
    notifyListeners();
  }

  // Getters
  List<app_notification.Notification> get notifications => _notifications;
  List<app_notification.Notification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnreadNotifications => _unreadCount > 0;

  /// Inicializa o provider carregando notificações e configurando realtime
  Future<void> initialize() async {
    await loadNotifications();
    _setupRealtimeSubscription();
  }

  /// Carrega todas as notificações do usuário
  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final notifications = await NotificationService.loadNotifications();
      final unreadCount = await NotificationService.getUnreadCount();

      _notifications = notifications;
      _unreadCount = unreadCount;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega apenas notificações não lidas
  Future<void> loadUnreadNotifications() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final unreadNotifications = await NotificationService.loadNotifications(
          onlyUnread: true,
        );
      final readNotifications = await NotificationService.loadNotifications(
          onlyUnread: false,
        );

      _notifications = [...unreadNotifications, ...readNotifications];
      _unreadCount = unreadNotifications.length;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marca uma notificação como lida
  Future<void> markAsRead(String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);
      
      // Atualizar localmente
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Marca múltiplas notificações como lidas
  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    try {
      await NotificationService.markMultipleAsRead(notificationIds);
      
      // Atualizar localmente
      int markedCount = 0;
      for (int i = 0; i < _notifications.length; i++) {
        if (notificationIds.contains(_notifications[i].id) && !_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
          markedCount++;
        }
      }
      
      _unreadCount = (_unreadCount - markedCount).clamp(0, double.infinity).toInt();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Marca todas as notificações como lidas
  Future<void> markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
      
      // Atualizar localmente
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Deleta uma notificação
  Future<void> deleteNotification(String notificationId) async {
    try {
      await NotificationService.deleteNotification(notificationId);
      
      // Atualizar localmente
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final wasUnread = !_notifications[index].isRead;
        _notifications.removeAt(index);
        if (wasUnread) {
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Cria uma nova notificação
  Future<app_notification.Notification?> createNotification({
    required String userId,
    String? groupId,
    required app_notification.NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    DateTime? expiresAt,
  }) async {
    try {
      final notification = await NotificationService.createNotification(
        userId: userId,
        groupId: groupId,
        type: type,
        title: title,
        message: message,
        data: data,
        expiresAt: expiresAt,
      );

      // Adicionar localmente se for para o usuário atual
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == currentUserId) {
        _notifications.insert(0, notification);
        if (!notification.isRead) {
          _unreadCount++;
        }
        notifyListeners();
      }

      return notification;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Cria notificação de convite para grupo
  Future<app_notification.Notification?> createGroupInviteNotification({
    required String invitedUserId,
    required String groupId,
    required String groupName,
    required String inviterName,
  }) async {
    try {
      return await NotificationService.createGroupInviteNotification(
        invitedUserId: invitedUserId,
        groupId: groupId,
        groupName: groupName,
        inviterName: inviterName,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Cria notificação de vencimento de despesa
  Future<app_notification.Notification?> createExpenseDueNotification({
    required String userId,
    required String expenseId,
    required String expenseDescription,
    required DateTime dueDate,
    required double amount,
  }) async {
    try {
      return await NotificationService.createExpenseDueNotification(
        userId: userId,
        expenseId: expenseId,
        expenseDescription: expenseDescription,
        dueDate: dueDate,
        amount: amount,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Cria notificação de vencimento de cartão de crédito
  Future<app_notification.Notification?> createCreditCardDueNotification({
    required String userId,
    required String cardId,
    required String cardName,
    required DateTime dueDate,
    required double amount,
  }) async {
    try {
      return await NotificationService.createCreditCardDueNotification(
        userId: userId,
        cardId: cardId,
        cardName: cardName,
        dueDate: dueDate,
        amount: amount,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Limpa notificações expiradas
  Future<void> cleanExpiredNotifications() async {
    try {
      await NotificationService.cleanExpiredNotifications();
      
      // Remover localmente as notificações expiradas
      _notifications.removeWhere((notification) => notification.isExpired);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Verifica e cria notificações de vencimento
  Future<void> checkAndCreateDueNotifications() async {
    try {
      await NotificationService.checkAndCreateDueNotifications();
      // Recarregar notificações para pegar as novas criadas
      await loadUnreadNotifications();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Configura a subscrição em tempo real
  void _setupRealtimeSubscription() {
    try {
      _realtimeSubscription?.unsubscribe();
      
      _realtimeSubscription = NotificationService.subscribeToNotifications(
        onNotificationReceived: (notification) {
          _notifications.insert(0, notification);
          if (!notification.isRead) {
            _unreadCount++;
          }
          notifyListeners();
        },
        onNotificationUpdated: (notificationId) {
          // Recarregar a notificação específica ou todas as notificações
          loadNotifications();
        },
        onNotificationDeleted: (notificationId) {
          final index = _notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            final wasUnread = !_notifications[index].isRead;
            _notifications.removeAt(index);
            if (wasUnread) {
              _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
            }
            notifyListeners();
          }
        },
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Filtra notificações por tipo
  List<app_notification.Notification> getNotificationsByType(
    app_notification.NotificationType type,
  ) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Obtém notificações de um grupo específico
  List<app_notification.Notification> getGroupNotifications(String groupId) {
    return _notifications.where((n) => n.groupId == groupId).toList();
  }

  /// Limpa o erro atual
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Atualiza a contagem de não lidas manualmente
  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await NotificationService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.unsubscribe();
    super.dispose();
  }
}
