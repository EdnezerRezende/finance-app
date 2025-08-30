import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../services/supabase_service.dart';

class GroupProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Group> _userGroups = [];
  Group? _selectedGroup;
  List<GroupMember> _groupMembers = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Group> get userGroups => _userGroups;
  Group? get selectedGroup => _selectedGroup;
  List<GroupMember> get groupMembers => _groupMembers;
  List<GroupMember> get pendingInvites => _groupMembers.where((m) => m.status == 'pending').toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedGroupId => _selectedGroup?.id;

  // Inicialização - carrega grupos do usuário
  Future<void> initialize() async {
    await loadUserGroups();
    if (_userGroups.isNotEmpty && _selectedGroup == null) {
      _selectedGroup = _userGroups.first;
      notifyListeners();
    }
  }

  // Carrega todos os grupos do usuário atual
  Future<void> loadUserGroups() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // First get the group IDs for the user
      final memberResponse = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId)
          .eq('status', 'active');

      final groupIds = (memberResponse as List)
          .map((item) => item['group_id'] as String)
          .toList();

      if (groupIds.isEmpty) {
        _userGroups = [];
        return;
      }

      // Then get the groups
      final response = await _supabase
          .from('groups')
          .select('''
            id, name, description, created_by, created_at, updated_at
          ''')
          .inFilter('id', groupIds);

      _userGroups = (response as List)
          .map((json) => Group.fromJson(json))
          .toList();

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Seleciona um grupo específico
  void selectGroup(dynamic group) {
    if (group is Group) {
      _selectedGroup = group;
    } else if (group is String) {
      _selectedGroup = _userGroups.firstWhere(
        (g) => g.id == group,
        orElse: () => _userGroups.isNotEmpty ? _userGroups.first : throw Exception('Group not found'),
      );
    }
    notifyListeners();
  }

  // Cria um novo grupo
  Future<Group?> createGroup(String name, String description) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      // Criar o grupo
      final groupResponse = await _supabase
          .from('groups')
          .insert({
            'name': name,
            'description': description,
            'created_by': userId,
          })
          .select()
          .single();

      final newGroup = Group.fromJson(groupResponse);

      // Adicionar o criador como admin do grupo
      await _supabase
          .from('group_members')
          .insert({
            'group_id': newGroup.id,
            'user_id': userId,
            'role': 'admin',
            'status': 'active',
          });

      // Atualizar lista local
      _userGroups.add(newGroup);
      
      // Se é o primeiro grupo, selecionar automaticamente
      if (_selectedGroup == null) {
        _selectedGroup = newGroup;
      }

      notifyListeners();
      return newGroup;

    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Carrega membros de um grupo específico
  Future<void> loadGroupMembers(String groupId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await SupabaseService.getGroupMembers(groupId);
      _groupMembers = (response as List).map((json) {
        return GroupMember.fromJson(json);
      }).toList();

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convida um usuário para o grupo
  Future<bool> inviteUser(String groupId, String userEmail) async {
    return inviteUserToGroup(groupId, userEmail, 'member');
  }

  // Convida um usuário para o grupo
  Future<bool> inviteUserToGroup(String groupId, String userEmail, String role) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Usuário não autenticado');

      // Buscar usuário pelo email
      final userResponse = await _supabase
          .from('usuario')
          .select('id')
          .eq('email', userEmail)
          .single();

      final targetUserId = userResponse['id'];

      // Verificar se já é membro
      final existingMember = await _supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', targetUserId)
          .maybeSingle();

      if (existingMember != null) {
        throw Exception('Usuário já é membro deste grupo');
      }

      // Adicionar como membro
      await _supabase
          .from('group_members')
          .insert({
            'group_id': groupId,
            'user_id': targetUserId,
            'role': role,
            'status': 'active',
            'invited_by': currentUserId,
          });

      // Recarregar membros
      await loadGroupMembers(groupId);
      return true;

    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove um membro do grupo
  Future<bool> removeMemberFromGroup(String groupId, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      // Recarregar membros
      await loadGroupMembers(groupId);
      return true;

    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Atualiza o papel de um membro
  Future<bool> updateMemberRole(String groupId, String userId, String newRole) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabase
          .from('group_members')
          .update({'role': newRole})
          .eq('group_id', groupId)
          .eq('user_id', userId);

      // Recarregar membros
      await loadGroupMembers(groupId);
      return true;

    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verifica se o usuário atual é admin do grupo selecionado
  bool get isCurrentUserAdmin {
    if (_selectedGroup == null) return false;
    
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    return _groupMembers.any((member) => 
        member.userId == currentUserId && 
        member.groupId == _selectedGroup!.id && 
        member.isAdmin);
  }

  // Obtém membros de um grupo específico
  List<GroupMember> getGroupMembers(String groupId) {
    return _groupMembers.where((member) => member.groupId == groupId).toList();
  }

  // Responde a um convite
  Future<void> respondToInvite(String inviteId, bool accept) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (accept) {
        await _supabase
            .from('group_members')
            .update({
              'status': 'active',
              'joined_at': DateTime.now().toIso8601String(),
            })
            .eq('id', inviteId);
      } else {
        await _supabase
            .from('group_members')
            .delete()
            .eq('id', inviteId);
      }

      // Recarregar grupos se aceito
      if (accept) {
        await loadUserGroups();
      }

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Exclui um grupo
  Future<void> deleteGroup(String groupId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _supabase
          .from('groups')
          .delete()
          .eq('id', groupId);

      // Remover da lista local
      _userGroups.removeWhere((group) => group.id == groupId);
      
      // Se era o grupo selecionado, selecionar outro
      if (_selectedGroup?.id == groupId) {
        _selectedGroup = _userGroups.isNotEmpty ? _userGroups.first : null;
      }

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Limpa dados ao fazer logout
  void clear() {
    _userGroups.clear();
    _selectedGroup = null;
    _groupMembers.clear();
    _error = null;
    notifyListeners();
  }
}
