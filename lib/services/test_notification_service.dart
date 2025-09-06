import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as app_notification;
import 'notification_service.dart';

/// Serviço para testar criação manual de notificações
class TestNotificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Testa criação de notificação simples
  static Future<void> testCreateSimpleNotification() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      print('🧪 Testando criação de notificação simples...');
      
      final notification = await NotificationService.createNotification(
        userId: userId,
        type: app_notification.NotificationType.general,
        title: 'Teste de Notificação',
        message: 'Esta é uma notificação de teste criada manualmente.',
        data: {
          'test': true,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Notificação criada com sucesso: ${notification.id}');
      print('📋 Título: ${notification.title}');
      print('💬 Mensagem: ${notification.message}');
      
    } catch (e) {
      print('❌ Erro ao criar notificação de teste: $e');
      rethrow;
    }
  }

  /// Testa criação de notificação de vencimento de despesa
  static Future<void> testCreateExpenseDueNotification() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      print('🧪 Testando criação de notificação de vencimento...');
      
      final notification = await NotificationService.createExpenseDueNotification(
        userId: userId,
        expenseId: '999',
        expenseDescription: 'Conta de Luz - Teste',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        amount: 150.50,
      );

      print('✅ Notificação de vencimento criada: ${notification.id}');
      print('📋 Título: ${notification.title}');
      print('💬 Mensagem: ${notification.message}');
      
    } catch (e) {
      print('❌ Erro ao criar notificação de vencimento: $e');
      rethrow;
    }
  }

  /// Testa criação de notificação de convite para grupo
  static Future<void> testCreateGroupInviteNotification() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      print('🧪 Testando criação de notificação de convite...');
      
      final notification = await NotificationService.createGroupInviteNotification(
        invitedUserId: userId,
        groupId: 'test-group-id',
        groupName: 'Grupo de Teste',
        inviterName: 'Usuário Teste',
      );

      print('✅ Notificação de convite criada: ${notification.id}');
      print('📋 Título: ${notification.title}');
      print('💬 Mensagem: ${notification.message}');
      
    } catch (e) {
      print('❌ Erro ao criar notificação de convite: $e');
      rethrow;
    }
  }

  /// Testa carregamento de notificações
  static Future<void> testLoadNotifications() async {
    try {
      print('🧪 Testando carregamento de notificações...');
      
      final notifications = await NotificationService.loadNotifications();
      
      print('✅ Notificações carregadas: ${notifications.length}');
      
      if (notifications.isEmpty) {
        print('📭 Nenhuma notificação encontrada');
      } else {
        print('📬 Notificações encontradas:');
        for (final notification in notifications) {
          print('  - ${notification.title} (${notification.type.value})');
          print('    ${notification.message}');
          print('    Criada em: ${notification.createdAt}');
          print('    Lida: ${notification.isRead}');
          print('');
        }
      }
      
    } catch (e) {
      print('❌ Erro ao carregar notificações: $e');
      rethrow;
    }
  }

  /// Testa contagem de notificações não lidas
  static Future<void> testUnreadCount() async {
    try {
      print('🧪 Testando contagem de não lidas...');
      
      final count = await NotificationService.getUnreadCount();
      
      print('✅ Notificações não lidas: $count');
      
    } catch (e) {
      print('❌ Erro ao obter contagem: $e');
      rethrow;
    }
  }

  /// Executa todos os testes
  static Future<void> runAllTests() async {
    print('🚀 Iniciando testes de notificação...\n');
    
    try {
      // Teste 1: Carregar notificações existentes
      await testLoadNotifications();
      print('---\n');
      
      // Teste 2: Contagem de não lidas
      await testUnreadCount();
      print('---\n');
      
      // Teste 3: Criar notificação simples
      await testCreateSimpleNotification();
      print('---\n');
      
      // Teste 4: Criar notificação de vencimento
      await testCreateExpenseDueNotification();
      print('---\n');
      
      // Teste 5: Criar notificação de convite
      await testCreateGroupInviteNotification();
      print('---\n');
      
      // Teste 6: Carregar novamente para ver as novas
      print('🔄 Carregando notificações após criação...');
      await testLoadNotifications();
      
      print('🎉 Todos os testes concluídos!');
      
    } catch (e) {
      print('💥 Falha nos testes: $e');
      rethrow;
    }
  }

  /// Verifica se a tabela de notificações existe e tem as colunas corretas
  static Future<void> checkNotificationTableStructure() async {
    try {
      print('🔍 Verificando estrutura da tabela notifications...');
      
      // Tentar fazer uma consulta simples para verificar se a tabela existe
      final result = await _supabase
          .from('notifications')
          .select('id')
          .limit(1);
      
      print('✅ Tabela notifications existe e é acessível');
      print('📊 Registros encontrados: ${result.length}');
      
      // Tentar inserir e deletar um registro de teste
      final testData = {
        'user_id': _supabase.auth.currentUser?.id,
        'type': 'general',
        'title': 'Teste de Estrutura',
        'message': 'Testando se a inserção funciona',
        'data': {'test': true},
      };
      
      final inserted = await _supabase
          .from('notifications')
          .insert(testData)
          .select()
          .single();
      
      print('✅ Inserção funcionando - ID: ${inserted['id']}');
      
      // Deletar o registro de teste
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', inserted['id']);
      
      print('✅ Deleção funcionando');
      print('🎯 Estrutura da tabela está correta!');
      
    } catch (e) {
      print('❌ Erro na verificação da tabela: $e');
      
      if (e.toString().contains('relation "notifications" does not exist')) {
        print('💡 A tabela notifications não existe. Execute o schema SQL primeiro.');
      } else if (e.toString().contains('permission denied')) {
        print('💡 Problema de permissões RLS. Verifique as políticas de segurança.');
      } else if (e.toString().contains('column') && e.toString().contains('does not exist')) {
        print('💡 Alguma coluna está faltando na tabela.');
      }
      
      rethrow;
    }
  }
}
