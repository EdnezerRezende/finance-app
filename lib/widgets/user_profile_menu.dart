import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/notification_provider.dart';
import '../providers/group_provider.dart';
import '../screens/notifications_screen.dart';
import '../screens/group_management_screen.dart';
import '../screens/whatsapp_integration_screen.dart';

/// Menu de perfil do usuário com avatar, badge de notificações e dropdown
class UserProfileMenu extends StatefulWidget {
  const UserProfileMenu({Key? key}) : super(key: key);

  @override
  State<UserProfileMenu> createState() => _UserProfileMenuState();
}

class _UserProfileMenuState extends State<UserProfileMenu> {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final userEmail = user?.email ?? '';
    final firstLetter = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U';

    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildProfileAvatar(firstLetter, notificationProvider.unreadCount),
          onSelected: (value) => _handleMenuSelection(context, value),
          itemBuilder: (BuildContext context) => [
            // Header com informações do usuário
            PopupMenuItem<String>(
              enabled: false,
              child: _buildUserHeader(userEmail),
            ),
            const PopupMenuDivider(),
            
            // Notificações
            PopupMenuItem<String>(
              value: 'notifications',
              child: _buildMenuItem(
                Icons.notifications,
                'Notificações',
                badge: notificationProvider.unreadCount > 0 
                    ? notificationProvider.unreadCount.toString() 
                    : null,
              ),
            ),
            
            // Administração de Grupos
            PopupMenuItem<String>(
              value: 'groups',
              child: _buildMenuItem(
                Icons.group,
                'Administrar Grupos',
              ),
            ),
            
            // Integração WhatsApp
            PopupMenuItem<String>(
              value: 'whatsapp',
              child: _buildMenuItem(
                Icons.chat,
                'WhatsApp',
              ),
            ),
            
            const PopupMenuDivider(),
            
            // Logout
            PopupMenuItem<String>(
              value: 'logout',
              child: _buildMenuItem(
                Icons.logout,
                'Sair',
                isDestructive: true,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Constrói o avatar do perfil com badge de notificações
  Widget _buildProfileAvatar(String firstLetter, int unreadCount) {
    return Container(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          // Avatar circular com primeira letra
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Badge de notificações
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Constrói o header do menu com informações do usuário
  Widget _buildUserHeader(String email) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Conta',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Constrói um item do menu
  Widget _buildMenuItem(
    IconData icon,
    String title, {
    String? badge,
    bool isDestructive = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDestructive ? Colors.red : Colors.grey[700],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDestructive ? Colors.red : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Manipula a seleção de itens do menu
  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'notifications':
        _navigateToNotifications(context);
        break;
      case 'groups':
        _navigateToGroupManagement(context);
        break;
      case 'whatsapp':
        _navigateToWhatsApp(context);
        break;
      case 'logout':
        _showLogoutConfirmation(context);
        break;
    }
  }

  /// Navega para a tela de notificações
  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  /// Navega para a tela de administração de grupos
  void _navigateToGroupManagement(BuildContext context) {
    // TODO: Implementar tela de administração de grupos
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GroupManagementScreen(),
      ),
    );
  }

  void _navigateToWhatsApp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WhatsAppIntegrationScreen(),
      ),
    );
  }

  /// Mostra confirmação de logout
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Saída'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  /// Executa o logout
  void _performLogout(BuildContext context) async {
    try {
      // Limpar dados dos providers
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      
      groupProvider.clearData();
      notificationProvider.clearData();
      
      // Fazer logout no Supabase
      await _supabase.auth.signOut();
      
      // Navegar para tela de login (assumindo que existe uma rota named)
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
