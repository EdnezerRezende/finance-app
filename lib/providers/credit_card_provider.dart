import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/credit_card.dart';
import '../services/supabase_service.dart';

class CreditCardProvider with ChangeNotifier {
  List<CreditCard> _creditCards = [];
  bool _isLoading = false;
  String? _error;
  String? _currentGroupId;

  List<CreditCard> get creditCards => _creditCards;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentGroupId => _currentGroupId;

  // Setter para atualizar o grupo atual
  void setCurrentGroup(String? groupId) {
    if (_currentGroupId != groupId) {
      _currentGroupId = groupId;
      _creditCards.clear(); // Limpar dados antigos
      notifyListeners();
    }
  }

  double get totalLimit => _creditCards.fold(0, (sum, card) => sum + card.creditLimit);
  double get totalBalance => _creditCards.fold(0, (sum, card) => sum + card.currentBalance);
  double get totalAvailableLimit => _creditCards.fold(0, (sum, card) => sum + card.availableLimit);

  Future<void> loadCreditCards() async {
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
      final data = await SupabaseService.getCreditCards(groupId: _currentGroupId);
      _creditCards = data.map((json) => CreditCard.fromSupabase(json)).toList();
    } catch (e) {
      _error = 'Erro ao carregar cartões: $e';
      debugPrint('Error loading credit cards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCreditCard(CreditCard card) async {
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
      final newCard = CreditCard(
        id: const Uuid().v4(),
        name: card.name,
        cardNumberMasked: card.cardNumberMasked,
        bankName: card.bankName,
        cardType: card.cardType,
        creditLimit: card.creditLimit,
        availableLimit: card.creditLimit,
        currentBalance: 0.0,
        closingDay: card.closingDay,
        dueDay: card.dueDay,
        cardColor: card.cardColor,
        groupId: _currentGroupId,
      );

      final data = await SupabaseService.insertCreditCard(newCard.toSupabase());
      final savedCard = CreditCard.fromSupabase(data);
      
      _creditCards.add(savedCard);
    } catch (e) {
      _error = 'Erro ao adicionar cartão: $e';
      debugPrint('Error adding credit card: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCreditCard(CreditCard card) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.updateCreditCard(card.id, card.toSupabase());
      
      final index = _creditCards.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        _creditCards[index] = card;
      }
    } catch (e) {
      _error = 'Erro ao atualizar cartão: $e';
      debugPrint('Error updating credit card: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCreditCard(String id) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.deleteCreditCard(id);
      _creditCards.removeWhere((card) => card.id == id);
    } catch (e) {
      _error = 'Erro ao deletar cartão: $e';
      debugPrint('Error deleting credit card: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCardBalance(String cardId, double newBalance) async {
    final index = _creditCards.indexWhere((card) => card.id == cardId);
    if (index != -1) {
      final updatedCard = _creditCards[index].copyWith(
        currentBalance: newBalance,
        availableLimit: _creditCards[index].creditLimit - newBalance,
      );
      await updateCreditCard(updatedCard);
    }
  }

  List<CreditCard> getCardsWithHighUsage() {
    return _creditCards.where((card) => card.usagePercentage > 70).toList();
  }

  List<CreditCard> getCardsDueSoon() {
    final now = DateTime.now();
    return _creditCards.where((card) {
      final currentMonth = DateTime(now.year, now.month, card.dueDay);
      final nextMonth = DateTime(now.year, now.month + 1, card.dueDay);
      final dueDate = currentMonth.isAfter(now) ? currentMonth : nextMonth;
      final daysUntilDue = dueDate.difference(now).inDays;
      return daysUntilDue <= 7 && daysUntilDue >= 0;
    }).toList();
  }
}