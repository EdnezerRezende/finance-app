import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../services/supabase_service.dart';
import 'encryption_provider.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  String? _currentGroupId;
  EncryptionProvider? _encryptionProvider;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentGroupId => _currentGroupId;

  // Setter para atualizar o grupo atual
  void setCurrentGroup(String? groupId) {
    if (_currentGroupId != groupId) {
      _currentGroupId = groupId;
      _transactions.clear(); // Limpar dados antigos
      notifyListeners();
    }
  }

  // Setter para o encryption provider
  void setEncryptionProvider(EncryptionProvider encryptionProvider) {
    _encryptionProvider = encryptionProvider;
  }
  
  List<Transaction> getExpensesByMonth(DateTime selectedMonth) {
    return _transactions.where((t) => 
      t.type == "DESPESA" && 
      t.date.year == selectedMonth.year && 
      t.date.month == selectedMonth.month
    ).toList();
  }
  
  List<Transaction> getIncomesByMonth(DateTime selectedMonth) {
    return _transactions.where((t) => 
      t.type == "ENTRADA" && 
      t.date.year == selectedMonth.year && 
      t.date.month == selectedMonth.month
    ).toList();
  }

  // Legacy getters for backward compatibility - now use current month
  List<Transaction> get expenses {
    final currentMonth = DateTime.now();
    return getExpensesByMonth(currentMonth);
  }
  
  List<Transaction> get incomes {
    final currentMonth = DateTime.now();
    return getIncomesByMonth(currentMonth);
  }

  double get totalExpenses => expenses.fold(0, (sum, t) => sum + t.amount);
  double get totalIncomes => incomes.fold(0, (sum, t) => sum + t.amount);
  double get balance => totalIncomes - totalExpenses;

  List<Transaction> getTransactionsByMonth(DateTime month) {
    return _transactions.where((t) {
      return t.date.year == month.year && t.date.month == month.month;
    }).toList();
  }

  List<Transaction> getTransactionsByCategory(String categoryId) {
    return _transactions.where((t) => t.categoryId == categoryId).toList();
  }

  List<Transaction> getTransactionsByCategoryName(String categoryName) {
    return _transactions.where((t) => t.categoryName == categoryName).toList();
  }

  Future<void> loadTransactions({DateTime? month}) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    if (_currentGroupId == null) {
      _error = 'Nenhum grupo selecionado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await SupabaseService.getExpenses(month: month, groupId: _currentGroupId);
      
      // Descriptografar dados se a criptografia estiver habilitada
      if (_encryptionProvider?.isEncryptionEnabled == true) {
        _transactions = data.map((json) => Transaction.fromSupabaseEncrypted(
          json, 
          _encryptionProvider!.decryptField, 
          _encryptionProvider!.decryptNumericField
        )).toList();
      } else {
        _transactions = data.map((json) => Transaction.fromSupabase(json)).toList();
      }
      
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _error = 'Erro ao carregar transações: $e';
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load current month transactions
  Future<void> loadCurrentMonthTransactions() async {
    await loadTransactions(month: DateTime.now());
  }

  // Load transactions by date range
  Future<void> loadTransactionsByDateRange(DateTime startDate, DateTime endDate) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    if (_currentGroupId == null) {
      _error = 'Nenhum grupo selecionado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await SupabaseService.getExpensesByDateRange(startDate, endDate, groupId: _currentGroupId);
      
      // Descriptografar dados se a criptografia estiver habilitada
      if (_encryptionProvider?.isEncryptionEnabled == true) {
        _transactions = data.map((json) => Transaction.fromSupabaseEncrypted(
          json, 
          _encryptionProvider!.decryptField, 
          _encryptionProvider!.decryptNumericField
        )).toList();
      } else {
        _transactions = data.map((json) => Transaction.fromSupabase(json)).toList();
      }
      
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _error = 'Erro ao carregar transações: $e';
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    if (_currentGroupId == null) {
      _error = 'Nenhum grupo selecionado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create new transaction with group ID
      final newTransaction = Transaction(
        id: 0, // Auto-generated by database
        type: transaction.type,
        amount: transaction.amount,
        description: transaction.description,
        category: transaction.category,
        date: transaction.date,
        userId: transaction.userId,
        groupId: _currentGroupId,
      );

      // Criptografar dados antes de salvar se a criptografia estiver habilitada
      Map<String, dynamic> transactionData;
      if (_encryptionProvider?.isEncryptionEnabled == true) {
        debugPrint('🔐 Criptografia HABILITADA - Criptografando transação');
        debugPrint('🔐 Dados originais: ${newTransaction.description} - ${newTransaction.amount}');
        transactionData = newTransaction.toSupabaseEncrypted(
          _encryptionProvider!.encryptField,
          _encryptionProvider!.encryptNumericField
        );
        debugPrint('🔐 Dados criptografados: ${transactionData['description']} - ${transactionData['amount']}');
      } else {
        debugPrint('❌ Criptografia DESABILITADA - Salvando dados sem criptografia');
        transactionData = newTransaction.toSupabase();
      }
      
      final data = await SupabaseService.insertExpense(transactionData);
      
      // Descriptografar dados ao criar o objeto de retorno
      Transaction savedTransaction;
      if (_encryptionProvider?.isEncryptionEnabled == true) {
        savedTransaction = Transaction.fromSupabaseEncrypted(
          data,
          _encryptionProvider!.decryptField,
          _encryptionProvider!.decryptNumericField
        );
      } else {
        savedTransaction = Transaction.fromSupabase(data);
      }
      
      _transactions.add(savedTransaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _error = 'Erro ao adicionar transação: $e';
      debugPrint('Error adding transaction: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Criptografar dados antes de atualizar se a criptografia estiver habilitada
      Map<String, dynamic> transactionData;
      if (_encryptionProvider?.isEncryptionEnabled == true) {
        debugPrint('🔐 Criptografia HABILITADA - Criptografando transação atualizada');
        debugPrint('🔐 Dados originais: ${transaction.description} - ${transaction.amount}');
        transactionData = transaction.toSupabaseEncrypted(
          _encryptionProvider!.encryptField,
          _encryptionProvider!.encryptNumericField
        );
        debugPrint('🔐 Dados criptografados: ${transactionData['description']} - ${transactionData['amount']}');
      } else {
        debugPrint('❌ Criptografia DESABILITADA - Atualizando dados sem criptografia');
        transactionData = transaction.toSupabase();
      }
      
      await SupabaseService.updateExpense(transaction.id, transactionData);
      
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (e) {
      _error = 'Erro ao atualizar transação: $e';
      debugPrint('Error updating transaction: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(int id) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.deleteExpense(id);
      _transactions.removeWhere((t) => t.id == id);
    } catch (e) {
      _error = 'Erro ao deletar transação: $e';
      debugPrint('Error deleting transaction: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePaymentStatus(int transactionId) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    try {
      final transactionIndex = _transactions.indexWhere((t) => t.id == transactionId);
      if (transactionIndex == -1) return;

      final transaction = _transactions[transactionIndex];
      final updatedTransaction = transaction.copyWith(isPago: !transaction.isPago);

      // Update in database
      await SupabaseService.updateExpense(transactionId, updatedTransaction.toSupabase());
      
      // Update local state
      _transactions[transactionIndex] = updatedTransaction;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao atualizar status de pagamento: $e';
      debugPrint('Error toggling payment status: $e');
      notifyListeners();
    }
  }

  Map<String, double> getCategoryTotals() {
    final Map<String, double> totals = {};
    
    for (final transaction in _transactions) {
      if (transaction.isExpense) {
        totals[transaction.category] = 
            (totals[transaction.category] ?? 0) + transaction.amount;
      }
    }
    
    return totals;
  }

  Map<String, double> getCategoryTotalsByMonth(DateTime month) {
    final Map<String, double> totals = {};
    final monthTransactions = getTransactionsByMonth(month);
    
    for (final transaction in monthTransactions) {
      if (transaction.type == "DESPESA") {
        totals[transaction.category] = 
            (totals[transaction.category] ?? 0) + transaction.amount;
      }
    }
    
    return totals;
  }

  Map<String, double> getExpensesByCategory() {
    final Map<String, double> totals = {};
    
    for (final transaction in expenses) {
      if (totals.containsKey(transaction.category)) {
        totals[transaction.category] = 
            totals[transaction.category]! + transaction.amount;
      } else {
        totals[transaction.category] = transaction.amount;
      }
    }
    
    return totals;
  }

  Map<String, double> getIncomesByCategory() {
    final Map<String, double> totals = {};
    
    for (final transaction in incomes) {
      if (totals.containsKey(transaction.category)) {
        totals[transaction.category] = 
            totals[transaction.category]! + transaction.amount;
      } else {
        totals[transaction.category] = transaction.amount;
      }
    }
    
    return totals;
  }
} 