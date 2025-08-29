import 'package:flutter/foundation.dart';
import '../models/finance.dart';
import '../services/supabase_service.dart';

class FinanceProvider with ChangeNotifier {
  List<Finance> _finances = [];
  bool _isLoading = false;
  String? _error;

  List<Finance> get finances => _finances;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtrar por tipo
  List<Finance> getFinancesByType(FinanceType type) {
    return _finances.where((f) => f.tipo.toLowerCase() == type.displayName.toLowerCase()).toList();
  }

  // Estatísticas
  double get totalValorFinanciado {
    return _finances.fold(0.0, (sum, finance) => sum + (finance.valorTotal ?? 0.0));
  }

  double get totalSaldoDevedor {
    return _finances.fold(0.0, (sum, finance) => sum + (finance.saldoDevedor ?? 0.0));
  }

  double get totalValorPago {
    return _finances.fold(0.0, (sum, finance) => sum + (finance.valorPago ?? 0.0));
  }

  double get totalDescontos {
    return _finances.fold(0.0, (sum, finance) => sum + (finance.valorDesconto ?? 0.0));
  }

  int get totalParcelasPagas {
    return _finances.fold(0, (sum, finance) => sum + finance.parcelasPagas);
  }

  int get totalParcelas {
    return _finances.fold(0, (sum, finance) => sum + (finance.quantidadeParcelas ?? 0));
  }

  double get percentualGeralPago {
    if (totalParcelas == 0) return 0.0;
    return (totalParcelasPagas / totalParcelas) * 100;
  }

  Future<void> loadFinances() async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await SupabaseService.getFinanceRecords();
      _finances = data.map((json) => Finance.fromSupabase(json)).toList();
    } catch (e) {
      _error = 'Erro ao carregar financiamentos: $e';
      debugPrint('Error loading finances: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFinance(Finance finance) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await SupabaseService.insertFinance(finance.toSupabase());
      final newFinance = Finance.fromSupabase(data);
      _finances.insert(0, newFinance);
    } catch (e) {
      _error = 'Erro ao adicionar financiamento: $e';
      debugPrint('Error adding finance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateFinance(Finance finance) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await SupabaseService.updateFinance(finance.id, finance.toSupabase());
      final updatedFinance = Finance.fromSupabase(data);
      
      final index = _finances.indexWhere((f) => f.id == finance.id);
      if (index != -1) {
        _finances[index] = updatedFinance;
      }
    } catch (e) {
      _error = 'Erro ao atualizar financiamento: $e';
      debugPrint('Error updating finance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFinance(int id) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.deleteFinance(id);
      _finances.removeWhere((f) => f.id == id);
    } catch (e) {
      _error = 'Erro ao excluir financiamento: $e';
      debugPrint('Error deleting finance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateParcelas(int financeId, List<int> parcelasQuitadas, double? valorDesconto, double? valorPago) async {
    final financeIndex = _finances.indexWhere((f) => f.id == financeId);
    if (financeIndex == -1) return;

    final finance = _finances[financeIndex];
    final updatedFinance = finance.copyWith(
      parcelasQuitadas: parcelasQuitadas,
      valorDesconto: valorDesconto,
      valorPago: valorPago,
    );

    await updateFinance(updatedFinance);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
