import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../providers/group_provider.dart';
import '../models/notification.dart' as app_notification;
import '../services/notification_service.dart';
import '../utils/dialog_utils.dart';

/// Tela principal de notificações
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Carregar notificações ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .loadNotifications(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                final unreadCount = provider.unreadCount;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Não lidas'),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Tab(text: 'Todas'),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) return const SizedBox.shrink();
              
              return TextButton(
                onPressed: () => _handleMenuAction(context, 'mark_all_read'),
                child: const Text('Marcar todas como lidas'),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Atualizar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clean_expired',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep),
                  title: Text('Limpar expiradas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'mark_all_read',
                child: ListTile(
                  leading: Icon(Icons.mark_email_read),
                  title: Text('Marcar todas como lidas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar notificações',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadNotifications(refresh: true),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Aba de não lidas
              _buildNotificationsList(
                context,
                provider.unreadNotifications,
                'Nenhuma notificação não lida',
                'Você está em dia com suas notificações! 🎉',
              ),
              
              // Aba de todas
              _buildNotificationsList(
                context,
                provider.notifications,
                'Nenhuma notificação',
                'Você ainda não possui notificações.',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    List<app_notification.Notification> notifications,
    String emptyTitle,
    String emptyMessage,
  ) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => Provider.of<NotificationProvider>(context, listen: false)
          .loadNotifications(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          
          return Dismissible(
            key: Key(notification.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            confirmDismiss: (direction) => _confirmDismiss(context, notification),
            onDismissed: (direction) async {
              final confirmed = await DialogUtils.showDeleteConfirmationDialog(
                context: context,
                title: 'Remover Notificação',
                message: 'Tem certeza que deseja remover esta notificação?\n\nEsta ação não pode ser desfeita.',
              );
              
              if (confirmed) {
                Provider.of<NotificationProvider>(context, listen: false)
                    .deleteNotification(notification.id);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notificação removida'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: _buildNotificationListItem(notification),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, app_notification.Notification notification) {
    // Navegar para tela específica baseada no tipo de notificação
    switch (notification.type) {
      case app_notification.NotificationType.groupInvite:
        _handleGroupInviteAction(context, notification);
        break;
      case app_notification.NotificationType.expenseDue:
      case app_notification.NotificationType.creditCardDue:
      case app_notification.NotificationType.financeDue:
        _handleDueNotificationAction(context, notification);
        break;
      default:
        // Para notificações gerais, apenas marcar como lida
        break;
    }
  }

  void _handleGroupInviteAction(BuildContext context, app_notification.Notification notification) {
    if (notification.data?['action_required'] == true) {
      final groupId = notification.data?['group_id'] as String?;
      final groupName = notification.data?['group_name'] as String?;
      final inviterName = notification.data?['inviter_name'] as String?;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Convite para Grupo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 16),
              if (groupName != null) ...[
                Text('Grupo: $groupName', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
              ],
              if (inviterName != null)
                Text('Convidado por: $inviterName'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _rejectGroupInvite(context, notification);
              },
              child: const Text('Recusar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _acceptGroupInvite(context, notification, groupId);
              },
              child: const Text('Aceitar'),
            ),
          ],
        ),
      );
    }
  }

  void _acceptGroupInvite(BuildContext context, app_notification.Notification notification, String? groupId) async {
    if (groupId == null) return;
    
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      
      // Recarregar grupos para incluir o novo grupo
      await groupProvider.loadUserGroups();
      
      // Marcar notificação como lida
      Provider.of<NotificationProvider>(context, listen: false)
          .markAsRead(notification.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Convite aceito! Você agora faz parte do grupo.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao aceitar convite: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rejectGroupInvite(BuildContext context, app_notification.Notification notification) async {
    try {
      final confirmed = await DialogUtils.showDeleteConfirmationDialog(
        context: context,
        title: 'Remover Notificação',
        message: 'Tem certeza que deseja remover esta notificação?\n\nEsta ação não pode ser desfeita.',
      );
      
      if (confirmed) {
        // Marcar notificação como lida e remover
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        await notificationProvider.deleteNotification(notification.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificação removida'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao recusar convite: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleDueNotificationAction(BuildContext context, app_notification.Notification notification) {
    final notificationType = notification.type;
    final data = notification.data ?? {};
    
    switch (notificationType) {
      case app_notification.NotificationType.creditCardDue:
        _handleCreditCardDueAction(context, notification, data);
        break;
      case app_notification.NotificationType.financeDue:
        _handleFinanceDueAction(context, notification, data);
        break;
      case app_notification.NotificationType.expenseDue:
        _handleExpenseDueAction(context, notification, data);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abrindo detalhes: ${notification.title}'),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  void _handleCreditCardDueAction(BuildContext context, app_notification.Notification notification, Map<String, dynamic> data) {
    final cardName = data['card_name'] as String? ?? 'Cartão';
    final amount = data['amount'] as double? ?? 0.0;
    final dueDate = data['due_date'] as String?;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vencimento: $cardName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            if (amount > 0) ...[
              Text('Valor: R\$ ${amount.toStringAsFixed(2)}', 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
            if (dueDate != null)
              Text('Vencimento: ${_formatDate(DateTime.parse(dueDate))}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navegar para tela de cartões de crédito
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navegando para cartões de crédito...')),
              );
            },
            child: const Text('Ver Cartão'),
          ),
        ],
      ),
    );
  }

  void _handleFinanceDueAction(BuildContext context, app_notification.Notification notification, Map<String, dynamic> data) {
    final financeType = data['finance_type'] as String? ?? 'Financiamento';
    final installmentNumber = data['installment_number'] as int? ?? 0;
    final totalInstallments = data['total_installments'] as int? ?? 0;
    final amount = data['amount'] as double? ?? 0.0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vencimento: $financeType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            if (installmentNumber > 0 && totalInstallments > 0) ...[
              Text('Parcela: $installmentNumber/$totalInstallments', 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
            if (amount > 0)
              Text('Valor: R\$ ${amount.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navegar para tela de financiamentos
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navegando para financiamentos...')),
              );
            },
            child: const Text('Ver Financiamento'),
          ),
        ],
      ),
    );
  }

  void _handleExpenseDueAction(BuildContext context, app_notification.Notification notification, Map<String, dynamic> data) {
    final expenseName = data['expense_name'] as String? ?? 'Despesa';
    final amount = data['amount'] as double? ?? 0.0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vencimento: $expenseName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            if (amount > 0)
              Text('Valor: R\$ ${amount.toStringAsFixed(2)}', 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navegar para tela de despesas
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navegando para despesas...')),
              );
            },
            child: const Text('Ver Despesa'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<bool?> _confirmDismiss(BuildContext context, app_notification.Notification notification) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover notificação'),
        content: const Text('Tem certeza que deseja remover esta notificação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  Future<void> _dismissNotification(BuildContext context, app_notification.Notification notification) async {
    final confirmed = await DialogUtils.showDeleteConfirmationDialog(
      context: context,
      title: 'Remover Notificação',
      message: 'Tem certeza que deseja remover esta notificação?\n\nEsta ação não pode ser desfeita.',
    );
    
    if (confirmed) {
      Provider.of<NotificationProvider>(context, listen: false)
          .deleteNotification(notification.id);
    }
  }

  void _showMarkAllAsReadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar todas como lidas'),
        content: const Text('Tem certeza que deseja marcar todas as notificações como lidas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<NotificationProvider>(context, listen: false)
                  .markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Todas as notificações foram marcadas como lidas'),
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationListItem(app_notification.Notification notification) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: notification.isRead ? Colors.grey[300] : Theme.of(context).primaryColor,
        child: Icon(
          _getNotificationIcon(notification.type),
          color: notification.isRead ? Colors.grey[600] : Colors.white,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.message),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      onTap: () => _handleNotificationTap(context, notification),
      onLongPress: () => _markAsRead(notification),
      trailing: PopupMenuButton<String>(
        onSelected: (action) {
          if (action == 'dismiss') {
            _dismissNotification(context, notification);
          } else if (action == 'mark_read') {
            _markAsRead(notification);
          }
        },
        itemBuilder: (context) => [
          if (!notification.isRead)
            const PopupMenuItem(
              value: 'mark_read',
              child: Row(
                children: [
                  Icon(Icons.mark_email_read, size: 16),
                  SizedBox(width: 8),
                  Text('Marcar como lida'),
                ],
              ),
            ),
          const PopupMenuItem(
            value: 'dismiss',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16),
                SizedBox(width: 8),
                Text('Remover'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(app_notification.NotificationType type) {
    switch (type) {
      case app_notification.NotificationType.groupInvite:
        return Icons.group_add;
      case app_notification.NotificationType.expenseDue:
        return Icons.payment;
      case app_notification.NotificationType.creditCardDue:
        return Icons.credit_card;
      case app_notification.NotificationType.financeDue:
        return Icons.account_balance;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _markAsRead(app_notification.Notification notification) async {
    if (notification.isRead) return;
    
    try {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      await provider.markAsRead(notification.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificação marcada como lida'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao marcar como lida: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    
    switch (action) {
      case 'refresh':
        provider.loadNotifications(refresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificações atualizadas')),
        );
        break;
      case 'clean_expired':
        provider.cleanExpiredNotifications().then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notificações expiradas removidas')),
          );
        });
        break;
      case 'mark_all_read':
        provider.markAllAsRead().then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todas as notificações marcadas como lidas')),
          );
        });
        break;
    }
  }
}
