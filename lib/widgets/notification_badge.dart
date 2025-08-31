import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

/// Badge de notificações para exibir contador de não lidas
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;
  final bool showZero;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
    this.showZero = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final unreadCount = notificationProvider.unreadCount;
        
        if (unreadCount == 0 && !showZero) {
          return child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: BoxConstraints(
                  minWidth: badgeSize ?? 20,
                  minHeight: badgeSize ?? 20,
                ),
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Ícone de notificação com badge integrado
class NotificationIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final double? size;
  final Color? color;

  const NotificationIcon({
    Key? key,
    this.onTap,
    this.icon = Icons.notifications,
    this.size,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      child: IconButton(
        icon: Icon(
          icon,
          size: size,
          color: color,
        ),
        onPressed: onTap,
      ),
    );
  }
}

/// Indicador de status de notificação (ponto colorido)
class NotificationStatusIndicator extends StatelessWidget {
  final bool hasUnread;
  final double size;
  final Color? readColor;
  final Color? unreadColor;

  const NotificationStatusIndicator({
    Key? key,
    required this.hasUnread,
    this.size = 8.0,
    this.readColor,
    this.unreadColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasUnread 
            ? (unreadColor ?? Colors.blue) 
            : (readColor ?? Colors.grey.shade300),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Widget para exibir contador de notificações em texto
class NotificationCounter extends StatelessWidget {
  final TextStyle? style;
  final String prefix;
  final String suffix;

  const NotificationCounter({
    Key? key,
    this.style,
    this.prefix = '',
    this.suffix = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final unreadCount = notificationProvider.unreadCount;
        
        if (unreadCount == 0) {
          return const SizedBox.shrink();
        }

        return Text(
          '$prefix$unreadCount$suffix',
          style: style ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        );
      },
    );
  }
}
