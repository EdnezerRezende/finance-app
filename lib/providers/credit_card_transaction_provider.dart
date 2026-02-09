import 'package:flutter/foundation.dart';
import '../models/credit_card_transaction.dart';
import '../models/credit_card_master.dart';
import '../services/supabase_service.dart';

class CreditCardTransactionProvider extends ChangeNotifier {
  List<CreditCardTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  String? _currentGroupId;

  List<CreditCardTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setCurrentGroup(String? groupId) {
    _currentGroupId = groupId;
    notifyListeners();
  }

  // Agrupar transações por cartão
  Map<String, List<CreditCardTransaction>> get transactionsByCard {
    final grouped = <String, List<CreditCardTransaction>>{};
    for (final transaction in _transactions) {
      if (!grouped.containsKey(transaction.creditCardId)) {
        grouped[transaction.creditCardId] = [];
      }
      grouped[transaction.creditCardId]!.add(transaction);
    }
    return grouped;
  }

  // Agrupar transações por mês/ano
  Map<String, List<CreditCardTransaction>> get transactionsByMonth {
    final grouped = <String, List<CreditCardTransaction>>{};
    for (final transaction in _transactions) {
      final monthKey = transaction.referenceKey;
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(transaction);
    }
    return grouped;
  }

  // Calcular resumo por cartão
  Map<String, Map<String, dynamic>> getCardSummaries(List<CreditCardMaster> cards) {
    final summaries = <String, Map<String, dynamic>>{};
    
    for (final card in cards) {
      final cardTransactions = _transactions.where((t) => t.creditCardId == card.id).toList();
      final totalBalance = cardTransactions.fold<double>(0, (sum, t) => sum + t.amount);
      final totalTransactions = cardTransactions.length;
      
      summaries[card.id] = {
        'card': card,
        'totalBalance': totalBalance,
        'totalTransactions': totalTransactions,
        'transactions': cardTransactions,
      };
    }
    
    return summaries;
  }

  Future<void> loadTransactions({int? month, int? year, String? cardId}) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_currentGroupId == null) {
        _error = 'Nenhum grupo selecionado';
        return;
      }
      
      final data = await SupabaseService.getCreditCardTransactions(
        groupId: _currentGroupId!,
        month: month,
        year: year,
        cardId: cardId,
      );
      _transactions = data.map((json) => CreditCardTransaction.fromSupabase(json)).toList();
    } catch (e) {
      _error = 'Erro ao carregar transações: $e';
      debugPrint('Error loading credit card transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(CreditCardTransaction transaction) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newTransaction = transaction.copyWith(
        groupId: _currentGroupId,
      );

      final transactionData = newTransaction.toSupabase(includeId: false);
      debugPrint('CreditCardTransactionProvider: Salvando transação');
      
      final data = await SupabaseService.insertCreditCardTransaction(transactionData);
      final savedTransaction = CreditCardTransaction.fromSupabase(data);
      
      _transactions.add(savedTransaction);
    } catch (e) {
      _error = 'Erro ao adicionar transação: $e';
      debugPrint('Error adding credit card transaction: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransactions(List<CreditCardTransaction> transactions) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      for (final transaction in transactions) {
        final newTransaction = transaction.copyWith(
          groupId: _currentGroupId,
        );

        final transactionData = newTransaction.toSupabase(includeId: false);
        final data = await SupabaseService.insertCreditCardTransaction(transactionData);
        final savedTransaction = CreditCardTransaction.fromSupabase(data);
        
        _transactions.add(savedTransaction);
      }
      
      debugPrint('CreditCardTransactionProvider: ${transactions.length} transações salvas');
    } catch (e) {
      _error = 'Erro ao adicionar transações: $e';
      debugPrint('Error adding credit card transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTransaction(CreditCardTransaction transaction) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final transactionData = transaction.toSupabase(includeId: true);
      debugPrint('CreditCardTransactionProvider: Atualizando transação');
      
      await SupabaseService.updateCreditCardTransaction(transaction.id, transactionData);
      
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
      }
    } catch (e) {
      _error = 'Erro ao atualizar transação: $e';
      debugPrint('Error updating credit card transaction: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.deleteCreditCardTransaction(id);
      _transactions.removeWhere((transaction) => transaction.id == id);
    } catch (e) {
      _error = 'Erro ao excluir transação: $e';
      debugPrint('Error deleting credit card transaction: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<CreditCardTransaction> getTransactionsByCard(String cardId) {
    return _transactions.where((t) => t.creditCardId == cardId).toList();
  }

  List<CreditCardTransaction> getTransactionsByMonth(int month, int year) {
    return _transactions.where((t) => 
      t.referenceMonth == month && t.referenceYear == year
    ).toList();
  }

  double getTotalByCard(String cardId) {
    return _transactions
      .where((t) => t.creditCardId == cardId)
      .fold<double>(0, (sum, t) => sum + t.amount);
  }

  double getTotalByMonth(int month, int year) {
    return _transactions
      .where((t) => t.referenceMonth == month && t.referenceYear == year)
      .fold<double>(0, (sum, t) => sum + t.amount);
  }
}
