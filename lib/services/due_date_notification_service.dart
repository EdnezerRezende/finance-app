import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart' as app_notification;
import '../services/notification_service.dart';

/// Serviço para gerenciar notificações de vencimento
class DueDateNotificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Verifica e cria notificações para vencimentos próximos
  static Future<void> checkAndCreateDueNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowStart = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      final tomorrowEnd = tomorrowStart.add(const Duration(days: 1));

      // Verificar cartões de crédito que vencem amanhã
      await _checkCreditCardsDue(userId, tomorrowStart, tomorrowEnd);
      
      // Verificar financiamentos que vencem amanhã
      await _checkFinancesDue(userId, tomorrowStart, tomorrowEnd);

    } catch (e) {
      print('Erro ao verificar vencimentos: $e');
    }
  }

  /// Verifica vencimentos de cartões de crédito
  static Future<void> _checkCreditCardsDue(
    String userId,
    DateTime tomorrowStart,
    DateTime tomorrowEnd,
  ) async {
    try {
      // Buscar cartões do usuário
      final cardsResponse = await _supabase
          .from('credit_cards')
          .select('id, card_name, due_day, current_balance')
          .eq('user_id', userId)
          .eq('is_active', true);

      for (final cardData in cardsResponse) {
        final dueDay = cardData['due_day'] as int? ?? 10;
        final cardName = cardData['card_name'] as String? ?? 'Cartão';
        final balance = _parseBalance(cardData['current_balance']);

        // Calcular próxima data de vencimento
        final now = DateTime.now();
        DateTime dueDate;
        
        if (now.day <= dueDay) {
          // Vence neste mês
          dueDate = DateTime(now.year, now.month, dueDay);
        } else {
          // Vence no próximo mês
          final nextMonth = now.month == 12 ? 1 : now.month + 1;
          final nextYear = now.month == 12 ? now.year + 1 : now.year;
          dueDate = DateTime(nextYear, nextMonth, dueDay);
        }

        // Verificar se vence amanhã
        if (dueDate.isAfter(tomorrowStart) && dueDate.isBefore(tomorrowEnd)) {
          // Verificar se já existe notificação para este vencimento
          final existingNotification = await _supabase
              .from('notifications')
              .select('id')
              .eq('user_id', userId)
              .eq('type', 'credit_card_due')
              .gte('created_at', tomorrowStart.subtract(const Duration(days: 2)).toIso8601String())
              .contains('data', {'card_id': cardData['id']})
              .maybeSingle();

          if (existingNotification == null) {
            // Criar notificação
            await NotificationService.createCreditCardDueNotification(
              userId: userId,
              cardId: cardData['id'].toString(),
              cardName: cardName,
              dueDate: dueDate,
              amount: balance,
            );
          }
        }
      }
    } catch (e) {
      print('Erro ao verificar vencimentos de cartões: $e');
    }
  }

  /// Verifica vencimentos de financiamentos
  static Future<void> _checkFinancesDue(
    String userId,
    DateTime tomorrowStart,
    DateTime tomorrowEnd,
  ) async {
    try {
      // Buscar financiamentos do usuário
      final financesResponse = await _supabase
          .from('finances')
          .select('id, tipo, "valorTotal", "quantidadeParcelas", "parcelasQuitadas", created_at')
          .eq('userId', userId);

      for (final financeData in financesResponse) {
        final tipo = financeData['tipo'] as String? ?? 'Financiamento';
        final totalParcelas = financeData['quantidadeParcelas'] as int? ?? 0;
        final parcelasQuitadas = (financeData['parcelasQuitadas'] as List?)?.cast<int>() ?? [];
        final createdAt = DateTime.parse(financeData['created_at']);
        final valorTotal = _parseBalance(financeData['valorTotal']);

        if (totalParcelas > 0) {
          // Calcular próxima parcela a vencer
          final proximaParcela = parcelasQuitadas.length + 1;
          
          if (proximaParcela <= totalParcelas) {
            // Calcular data de vencimento da próxima parcela (assumindo vencimento mensal)
            final dueDate = DateTime(
              createdAt.year,
              createdAt.month + proximaParcela - 1,
              createdAt.day,
            );

            // Verificar se vence amanhã
            if (dueDate.isAfter(tomorrowStart) && dueDate.isBefore(tomorrowEnd)) {
              // Verificar se já existe notificação para este vencimento
              final existingNotification = await _supabase
                  .from('notifications')
                  .select('id')
                  .eq('user_id', userId)
                  .eq('type', 'finance_due')
                  .gte('created_at', tomorrowStart.subtract(const Duration(days: 2)).toIso8601String())
                  .contains('data', {'finance_id': financeData['id']})
                  .maybeSingle();

              if (existingNotification == null) {
                final valorParcela = totalParcelas > 0 ? valorTotal / totalParcelas : 0.0;
                
                // Criar notificação
                await NotificationService.createNotification(
                  userId: userId,
                  type: app_notification.NotificationType.financeDue,
                  title: 'Parcela de financiamento a vencer',
                  message: 'A parcela $proximaParcela/$totalParcelas do $tipo vence amanhã',
                  data: {
                    'finance_id': financeData['id'],
                    'finance_type': tipo,
                    'installment_number': proximaParcela,
                    'total_installments': totalParcelas,
                    'due_date': dueDate.toIso8601String(),
                    'amount': valorParcela,
                    'days_until_due': 1,
                  },
                  expiresAt: dueDate.add(const Duration(days: 1)),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao verificar vencimentos de financiamentos: $e');
    }
  }

  /// Verifica vencimentos de transações recorrentes
  static Future<void> checkRecurringTransactionsDue(String userId) async {
    try {
      // TODO: Implementar quando tivermos transações recorrentes
      // Por enquanto, esta funcionalidade não está implementada
      // pois não temos um sistema de transações recorrentes definido
    } catch (e) {
      print('Erro ao verificar transações recorrentes: $e');
    }
  }

  /// Agenda verificação automática de vencimentos
  static Future<void> scheduleAutomaticChecks() async {
    // TODO: Implementar agendamento automático usando um timer ou background task
    // Por enquanto, será chamado manualmente quando necessário
    await checkAndCreateDueNotifications();
  }

  /// Parse seguro de valores monetários
  static double _parseBalance(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Remove notificações de vencimento antigas/expiradas
  static Future<void> cleanupExpiredDueNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .inFilter('type', ['credit_card_due', 'finance_due', 'expense_due'])
          .lt('expires_at', DateTime.now().toIso8601String());

    } catch (e) {
      print('Erro ao limpar notificações expiradas: $e');
    }
  }

  /// Cria notificação de teste para desenvolvimento
  static Future<void> createTestDueNotification() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await NotificationService.createCreditCardDueNotification(
        userId: userId,
        cardId: 'test_card',
        cardName: 'Cartão de Teste',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        amount: 1250.75,
      );

      await NotificationService.createNotification(
        userId: userId,
        type: app_notification.NotificationType.financeDue,
        title: 'Parcela de financiamento a vencer',
        message: 'A parcela 5/24 do Financiamento Imobiliário vence amanhã',
        data: {
          'finance_id': 'test_finance',
          'finance_type': 'Financiamento Imobiliário',
          'installment_number': 5,
          'total_installments': 24,
          'due_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'amount': 2500.00,
          'days_until_due': 1,
        },
        expiresAt: DateTime.now().add(const Duration(days: 2)),
      );

    } catch (e) {
      print('Erro ao criar notificações de teste: $e');
    }
  }
}
