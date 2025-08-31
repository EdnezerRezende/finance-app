import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart' as app_notification;
import '../providers/notification_provider.dart';

/// Item de notificação para exibição em lista
class NotificationListItem extends StatelessWidget {
  final app_notification.Notification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool showActions;

  const NotificationListItem({
    Key? key,
    required this.notification,
    this.onTap,
    this.onDismiss,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRead = notification.isRead;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isRead ? 1 : 3,
      child: InkWell(
        onTap: () {
          if (!isRead) {
            Provider.of<NotificationProvider>(context, listen: false)
                .markAsRead(notification.id);
          }
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícone da notificação
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTypeColor(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notification.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Conteúdo da notificação
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                  color: isRead ? theme.textTheme.bodyMedium?.color : null,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getTypeColor(notification.type),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isRead 
                                ? theme.textTheme.bodySmall?.color 
                                : theme.textTheme.bodyMedium?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        // Informações adicionais baseadas no tipo
                        if (notification.data != null)
                          _buildAdditionalInfo(context, notification),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Rodapé com data e ações
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(notification.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  if (showActions)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isRead)
                          TextButton(
                            onPressed: () {
                              Provider.of<NotificationProvider>(context, listen: false)
                                  .markAsRead(notification.id);
                            },
                            child: const Text('Marcar como lida'),
                          ),
                        if (onDismiss != null)
                          TextButton(
                            onPressed: onDismiss,
                            child: const Text('Dispensar'),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo(BuildContext context, app_notification.Notification notification) {
    final data = notification.data!;
    
    switch (notification.type) {
      case app_notification.NotificationType.groupInvite:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Icon(Icons.group, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Grupo: ${data['group_name']}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case app_notification.NotificationType.expenseDue:
      case app_notification.NotificationType.creditCardDue:
        final amount = data['amount'] as double?;
        final daysUntilDue = data['days_until_due'] as int?;
        
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getDueDateColor(daysUntilDue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: _getDueDateColor(daysUntilDue),
              ),
              const SizedBox(width: 8),
              if (amount != null && amount > 0)
              Text(
                'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getDueDateText(daysUntilDue),
                style: TextStyle(
                  fontSize: 12,
                  color: _getDueDateColor(daysUntilDue),
                ),
              ),
            ],
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getTypeColor(app_notification.NotificationType type) {
    switch (type) {
      case app_notification.NotificationType.groupInvite:
        return Colors.blue;
      case app_notification.NotificationType.expenseDue:
        return Colors.orange;
      case app_notification.NotificationType.creditCardDue:
        return Colors.red;
      case app_notification.NotificationType.budgetAlert:
        return Colors.purple;
      case app_notification.NotificationType.financeDue:
        return Colors.green;
      case app_notification.NotificationType.general:
        return Colors.grey;
    }
  }

  Color _getDueDateColor(int? daysUntilDue) {
    if (daysUntilDue == null) return Colors.grey;
    if (daysUntilDue <= 0) return Colors.red;
    if (daysUntilDue == 1) return Colors.orange;
    return Colors.blue;
  }

  String _getDueDateText(int? daysUntilDue) {
    if (daysUntilDue == null) return '';
    if (daysUntilDue < 0) return 'Vencido';
    if (daysUntilDue == 0) return 'Vence hoje';
    if (daysUntilDue == 1) return 'Vence amanhã';
    return 'Vence em $daysUntilDue dias';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }
}
