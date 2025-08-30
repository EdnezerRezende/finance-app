import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../models/group.dart';
import '../models/group_member.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  final _inviteEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().loadUserGroups();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    _inviteEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Grupos'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Meus Grupos', icon: Icon(Icons.group)),
            Tab(text: 'Criar Grupo', icon: Icon(Icons.add_circle)),
            Tab(text: 'Convites', icon: Icon(Icons.mail)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyGroupsTab(),
          _buildCreateGroupTab(),
          _buildInvitesTab(),
        ],
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        if (groupProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (groupProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  groupProvider.error!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => groupProvider.loadUserGroups(),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        final groups = groupProvider.userGroups;
        if (groups.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Você ainda não faz parte de nenhum grupo',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Crie um novo grupo ou aguarde um convite',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final isSelected = group.id == groupProvider.selectedGroupId;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isSelected ? 4 : 1,
              color: isSelected ? const Color(0xFF2E7D32).withOpacity(0.1) : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2E7D32),
                  child: Text(
                    group.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  group.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (group.description.isNotEmpty)
                      Text(group.description),
                    const SizedBox(height: 4),
                    Text(
                      '${group.memberCount} membros',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleGroupAction(value, group),
                      itemBuilder: (context) => [
                        if (!isSelected)
                          const PopupMenuItem(
                            value: 'select',
                            child: ListTile(
                              leading: Icon(Icons.radio_button_checked),
                              title: Text('Selecionar'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'members',
                          child: ListTile(
                            leading: Icon(Icons.people),
                            title: Text('Ver Membros'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'invite',
                          child: ListTile(
                            leading: Icon(Icons.person_add),
                            title: Text('Convidar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (group.isOwner)
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Excluir', style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                onTap: () => _selectGroup(group),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCreateGroupTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Criar Novo Grupo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Grupo',
                hintText: 'Ex: Família Silva, Apartamento 101',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira o nome do grupo';
                }
                if (value.trim().length < 3) {
                  return 'O nome deve ter pelo menos 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _groupDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Descreva o propósito do grupo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Consumer<GroupProvider>(
              builder: (context, groupProvider, child) {
                return ElevatedButton(
                  onPressed: groupProvider.isLoading ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: groupProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Criar Grupo',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitesTab() {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        final pendingInvites = groupProvider.pendingInvites;
        
        if (pendingInvites.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhum convite pendente',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingInvites.length,
          itemBuilder: (context, index) {
            final invite = pendingInvites[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2E7D32),
                  child: Icon(Icons.mail, color: Colors.white),
                ),
                title: Text('Convite para o grupo'),
                subtitle: Text('De: ${invite.invitedBy ?? 'Desconhecido'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _respondToInvite(invite.id, false),
                      child: const Text('Recusar', style: TextStyle(color: Colors.red)),
                    ),
                    ElevatedButton(
                      onPressed: () => _respondToInvite(invite.id, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aceitar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _selectGroup(Group group) {
    context.read<GroupProvider>().selectGroup(group.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Grupo "${group.name}" selecionado'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  void _handleGroupAction(String action, Group group) {
    switch (action) {
      case 'select':
        _selectGroup(group);
        break;
      case 'members':
        _showMembersDialog(group);
        break;
      case 'invite':
        _showInviteDialog(group);
        break;
      case 'delete':
        _showDeleteConfirmation(group);
        break;
    }
  }

  void _showMembersDialog(Group group) {
    // Load group members when dialog opens
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    groupProvider.loadGroupMembers(group.id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Membros de ${group.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer<GroupProvider>(
            builder: (context, groupProvider, child) {
              if (groupProvider.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              final members = groupProvider.getGroupMembers(group.id);
              
              if (members.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Nenhum membro encontrado'),
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text((member.userEmail ?? 'U').substring(0, 1).toUpperCase()),
                    ),
                    title: Text(member.userEmail ?? 'Email não disponível'),
                    subtitle: Text(_getRoleDisplayName(member.role)),
                    trailing: member.status == 'pending'
                        ? const Chip(
                            label: Text('Pendente'),
                            backgroundColor: Colors.orange,
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Convidar para ${group.name}'),
        content: TextField(
          controller: _inviteEmailController,
          decoration: const InputDecoration(
            labelText: 'Email do usuário',
            hintText: 'usuario@exemplo.com',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _sendInvite(group),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar Convite'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Grupo'),
        content: Text(
          'Tem certeza que deseja excluir o grupo "${group.name}"? '
          'Esta ação não pode ser desfeita e todos os dados compartilhados serão perdidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _deleteGroup(group),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final groupProvider = context.read<GroupProvider>();
    
    try {
      await groupProvider.createGroup(
        _groupNameController.text.trim(),
        _groupDescriptionController.text.trim(),
      );
      
      _groupNameController.clear();
      _groupDescriptionController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grupo criado com sucesso!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      
      _tabController.animateTo(0); // Voltar para a aba "Meus Grupos"
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar grupo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendInvite(Group group) async {
    final email = _inviteEmailController.text.trim();
    if (email.isEmpty) return;

    final groupProvider = context.read<GroupProvider>();
    
    try {
      await groupProvider.inviteUser(group.id, email);
      
      _inviteEmailController.clear();
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Convite enviado para $email'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar convite: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _respondToInvite(String inviteId, bool accept) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    await groupProvider.respondToInvite(inviteId, accept);
    
    if (accept) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Convite aceito!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Convite recusado!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'member':
        return 'Membro';
      case 'viewer':
        return 'Visualizador';
      default:
        return 'Membro';
    }
  }

  Future<void> _deleteGroup(Group group) async {
    Navigator.of(context).pop(); // Fechar dialog
    
    final groupProvider = context.read<GroupProvider>();
    
    try {
      await groupProvider.deleteGroup(group.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grupo excluído com sucesso'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir grupo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
