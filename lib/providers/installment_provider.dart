import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/purchase.dart';
import '../models/installment.dart';
import '../services/supabase_service.dart';

class InstallmentProvider with ChangeNotifier {
  List<Purchase> _purchases = [];
  List<Installment> _installments = [];
  bool _isLoading = false;
  String? _error;

  List<Purchase> get purchases => _purchases;
  List<Installment> get installments => _installments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get installments for current selected month
  List<Installment> currentMonthInstallments(DateTime selectedMonth) {
    return _installments.where((installment) {
      return installment.ano == selectedMonth.year && 
             installment.mes == selectedMonth.month;
    }).toList();
  }

  // Get installments by month
  List<Installment> getInstallmentsByMonth(DateTime month) {
    return _installments.where((installment) {
      return installment.ano == month.year && 
             installment.mes == month.month;
    }).toList();
  }

  // Get pending installments
  List<Installment> get pendingInstallments {
    return _installments.where((i) => i.isPending).toList();
  }

  // Get overdue installments
  List<Installment> get overdueInstallments {
    final now = DateTime.now();
    return _installments.where((i) => 
      i.isPending && 
      (i.ano < now.year || (i.ano == now.year && i.mes < now.month))
    ).toList();
  }

  // Get upcoming installments (next 30 days)
  List<Installment> get upcomingInstallments {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1);
    return _installments.where((installment) {
      return installment.isPending && 
             (installment.ano > now.year || 
              (installment.ano == now.year && installment.mes > now.month)) &&
             (installment.ano < nextMonth.year || 
              (installment.ano == nextMonth.year && installment.mes <= nextMonth.month));
    }).toList();
  }

  double get totalPendingAmount {
    return pendingInstallments.fold(0, (sum, i) => sum + i.valor);
  }

  double getTotalMonthAmount(DateTime selectedMonth) {
    return currentMonthInstallments(selectedMonth).fold(0.0, (sum, i) => sum + i.valor);
  }

  Future<void> loadInstallments({DateTime? month}) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await SupabaseService.getInstallments(month: month);
      _installments = data.map((json) {
        // Flatten the joined data
        final flatJson = Map<String, dynamic>.from(json);
        if (json['purchases'] != null) {
          flatJson['purchase_description'] = json['purchases']['description'];
          flatJson['merchant_name'] = json['purchases']['merchant_name'];
        }
        if (json['credit_cards'] != null) {
          flatJson['card_name'] = json['credit_cards']['card_name'];
        }
        return Installment.fromSupabase(flatJson);
      }).toList();
      
      _installments.sort((a, b) {
        final aDate = DateTime(a.ano, a.mes);
        final bDate = DateTime(b.ano, b.mes);
        return aDate.compareTo(bDate);
      });
    } catch (e) {
      _error = 'Erro ao carregar parcelas: $e';
      debugPrint('Error loading installments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPurchases({DateTime? month}) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await SupabaseService.getPurchases(month: month);
      _purchases = data.map((json) => Purchase.fromSupabase(json)).toList();
    } catch (e) {
      _error = 'Erro ao carregar compras: $e';
      debugPrint('Error loading purchases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPurchase({
    required String creditCardId,
    required String description,
    required double totalAmount,
    required int installmentsCount,
    required DateTime purchaseDate,
    required DateTime firstInstallmentDate,
    String? category,
    String? merchantName,
    String? notes,
  }) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final installmentAmount = totalAmount / installmentsCount;
      
      // Create purchase
      final purchase = Purchase(
        id: const Uuid().v4(),
        creditCardId: creditCardId,
        description: description,
        totalAmount: totalAmount,
        installmentsCount: installmentsCount,
        installmentAmount: installmentAmount,
        category: category,
        merchantName: merchantName,
        purchaseDate: purchaseDate,
        firstInstallmentDate: firstInstallmentDate,
        notes: notes,
      );

      final savedPurchase = await SupabaseService.insertPurchase(purchase.toSupabase());
      _purchases.add(Purchase.fromSupabase(savedPurchase));

      // Create installments
      for (int i = 1; i <= installmentsCount; i++) {
        final dueDate = DateTime(
          firstInstallmentDate.year,
          firstInstallmentDate.month + (i - 1),
          firstInstallmentDate.day,
        );

        final installment = Installment(
          id: const Uuid().v4(),
          valor: installmentAmount,
          parcelas: installmentsCount,
          parcelasPagas: 0,
          descricao: description,
          mes: dueDate.month,
          ano: dueDate.year,
          traceControll: purchase.id,
        );

        await SupabaseService.addInstallment(installment.toSupabase());
      }

      // Reload installments to get the new ones
      await loadInstallments();
    } catch (e) {
      _error = 'Erro ao adicionar compra: $e';
      debugPrint('Error adding purchase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> payInstallment(String installmentId, double amount, String paymentMethod, {String? notes}) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.payInstallment(installmentId, amount, paymentMethod, notes: notes);
      
      // Update local installment
      final index = _installments.indexWhere((i) => i.id == installmentId);
      if (index != -1) {
        _installments[index] = _installments[index].copyWith(
          status: 'paid',
          parcelasPagas: _installments[index].parcelasPagas + 1,
        );
      }
    } catch (e) {
      _error = 'Erro ao pagar parcela: $e';
      debugPrint('Error paying installment: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateInstallment(Installment installment) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.updateInstallment(installment.id, installment.toSupabase());
      
      final index = _installments.indexWhere((i) => i.id == installment.id);
      if (index != -1) {
        _installments[index] = installment;
      }
    } catch (e) {
      _error = 'Erro ao atualizar parcela: $e';
      debugPrint('Error updating installment: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addInstallment(Installment installment) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newInstallment = await SupabaseService.addInstallment(installment.toSupabase());
      _installments.add(Installment.fromSupabase(newInstallment));
    } catch (e) {
      _error = 'Erro ao adicionar parcela: $e';
      debugPrint('Error adding installment: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteInstallment(String installmentId) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.deleteInstallment(installmentId);
      _installments.removeWhere((i) => i.id == installmentId);
    } catch (e) {
      _error = 'Erro ao deletar parcela: $e';
      debugPrint('Error deleting installment: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
