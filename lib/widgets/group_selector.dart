import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../providers/group_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/credit_card_provider.dart';
import '../providers/installment_provider.dart';
import '../screens/group_management_screen.dart';

class GroupSelector extends StatelessWidget {
  const GroupSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        final selectedGroup = groupProvider.selectedGroup;
        final userGroups = groupProvider.userGroups;

        if (userGroups.isEmpty) {
          return IconButton(
            onPressed: () => _navigateToGroupManagement(context),
            icon: const Icon(Icons.group_add),
            tooltip: 'Criar Grupo',
          );
        }

        return PopupMenuButton<String>(
          onSelected: (value) => _handleMenuSelection(context, value, groupProvider),
          tooltip: 'Selecionar Grupo',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white,
                  child: Text(
                    selectedGroup?.name.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    selectedGroup?.name ?? 'Selecionar Grupo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => [
            // Header
            const PopupMenuItem<String>(
              enabled: false,
              child: Text(
                'Grupos Disponíveis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const PopupMenuDivider(),
            
            // Lista de grupos
            ...userGroups.map((group) => PopupMenuItem<String>(
              value: 'select_${group.id}',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF2E7D32),
                  child: Text(
                    group.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  group.name,
                  style: TextStyle(
                    fontWeight: group.id == selectedGroup?.id 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  '${group.memberCount} membros',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: group.id == selectedGroup?.id
                    ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                    : null,
              ),
            )),
            
            const PopupMenuDivider(),
            
            // Ações
            const PopupMenuItem<String>(
              value: 'manage',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.settings, color: Color(0xFF2E7D32)),
                title: Text('Gerenciar Grupos'),
              ),
            ),
            
            const PopupMenuItem<String>(
              value: 'create',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.add_circle, color: Color(0xFF2E7D32)),
                title: Text('Criar Novo Grupo'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleMenuSelection(BuildContext context, String value, GroupProvider groupProvider) {
    if (value.startsWith('select_')) {
      final groupId = value.substring(7); // Remove 'select_' prefix
      groupProvider.selectGroup(groupId);
      
      // Sincronizar todos os providers com o novo grupo
      _syncProvidersWithGroup(context, groupId);
      
      final selectedGroup = groupProvider.userGroups.firstWhere((g) => g.id == groupId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grupo "${selectedGroup.name}" selecionado'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (value == 'manage' || value == 'create') {
      _navigateToGroupManagement(context);
    }
  }

  void _syncProvidersWithGroup(BuildContext context, String? groupId) {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    final creditCardProvider = Provider.of<CreditCardProvider>(context, listen: false);
    final installmentProvider = Provider.of<InstallmentProvider>(context, listen: false);
    
    transactionProvider.setCurrentGroup(groupId);
    financeProvider.setCurrentGroup(groupId);
    creditCardProvider.setCurrentGroup(groupId);
    installmentProvider.setCurrentGroup(groupId);
    
    // Recarregar dados
    if (groupId != null) {
      transactionProvider.loadTransactions();
      financeProvider.loadFinances();
      creditCardProvider.loadCreditCards();
      // InstallmentProvider será recarregado automaticamente quando necessário
    }
  }

  void _navigateToGroupManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GroupManagementScreen(),
      ),
    );
  }
}

// Widget compacto para usar em espaços menores
class CompactGroupSelector extends StatelessWidget {
  const CompactGroupSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        final selectedGroup = groupProvider.selectedGroup;
        
        return IconButton(
          onPressed: () => _showGroupSelector(context),
          icon: CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white,
            child: Text(
              selectedGroup?.name.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          tooltip: selectedGroup?.name ?? 'Selecionar Grupo',
        );
      },
    );
  }

  void _showGroupSelector(BuildContext context) {
    final groupProvider = context.read<GroupProvider>();
    final userGroups = groupProvider.userGroups;
    
    if (userGroups.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const GroupManagementScreen(),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selecionar Grupo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            ...userGroups.map((group) => ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF2E7D32),
                child: Text(
                  group.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(group.name),
              subtitle: Text('${group.memberCount} membros'),
              trailing: group.id == groupProvider.selectedGroupId
                  ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                  : null,
              onTap: () {
                groupProvider.selectGroup(group.id);
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Grupo "${group.name}" selecionado'),
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                );
              },
            )),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF2E7D32)),
              title: const Text('Gerenciar Grupos'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GroupManagementScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
