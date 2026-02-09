import 'package:flutter/foundation.dart';
import '../models/credit_card.dart';
import '../services/supabase_service.dart';
import 'encryption_provider.dart';

class CreditCardProvider with ChangeNotifier {
  List<CreditCard> _creditCards = [];
  bool _isLoading = false;
  String? _error;
  String? _currentGroupId;
  EncryptionProvider? _encryptionProvider;

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

  // Setter para o encryption provider
  void setEncryptionProvider(EncryptionProvider provider) {
    _encryptionProvider = provider;
  }

  double get totalLimit => _creditCards.fold(0, (sum, card) => sum + card.creditLimit);
  double get totalBalance => _creditCards.fold(0, (sum, card) => sum + card.currentBalance);
  double get totalAvailableLimit => _creditCards.fold(0, (sum, card) => sum + card.availableLimit);

  Future<void> loadCreditCards({DateTime? month}) async {
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
      if (_currentGroupId == null) {
        _error = 'Nenhum grupo selecionado';
        return;
      }
      final selectedMonth = month ?? DateTime.now();
      final data = await SupabaseService.getCreditCards(groupId: _currentGroupId!, month: selectedMonth);
      
      // Carregar dados sem descriptografia
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
        id: '', // Será gerado pelo banco de dados
        name: card.name,
        cardNumberMasked: card.cardNumberMasked,
        bankName: card.bankName,
        cardType: card.cardType,
        creditLimit: card.creditLimit,
        availableLimit: card.availableLimit,
        currentBalance: card.currentBalance, // Manter o valor original
        closingDay: card.closingDay,
        dueDay: card.dueDay,
        cardColor: card.cardColor,
        groupId: _currentGroupId,
        mes: card.mes,
        ano: card.ano,
      );

      // Salvar dados sem criptografia
      final cardData = newCard.toSupabase(includeId: false); // Não incluir ID para inserção
      debugPrint('CreditCardProvider: Salvando cartão sem criptografia');
      
      final data = await SupabaseService.insertCreditCard(cardData);
      
      // Carregar dados sem descriptografia
      final savedCard = CreditCard.fromSupabase(data);
      debugPrint('CreditCardProvider: Cartão carregado sem criptografia');
      
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
      // Atualizar dados sem criptografia
      final cardData = card.toSupabase(includeId: true); // Incluir ID para atualização
      debugPrint('CreditCardProvider: Atualizando cartão sem criptografia');
      
      await SupabaseService.updateCreditCard(card.id, cardData);
      
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

  // Agrupar cartões por banco
  Map<String, List<CreditCard>> get creditCardsByBank {
    final grouped = <String, List<CreditCard>>{};
    for (final card in _creditCards) {
      final bankName = card.bankName;
      if (!grouped.containsKey(bankName)) {
        grouped[bankName] = [];
      }
      grouped[bankName]!.add(card);
    }
    return grouped;
  }

  // Calcular resumo por banco
  Map<String, Map<String, dynamic>> get bankSummaries {
    final summaries = <String, Map<String, dynamic>>{};
    final grouped = creditCardsByBank;
    
    for (final entry in grouped.entries) {
      final bankName = entry.key;
      final cards = entry.value;
      
      final totalBalance = cards.fold<double>(0, (sum, card) => sum + card.currentBalance);
      final totalTransactions = cards.length;
      final firstCard = cards.first;
      
      summaries[bankName] = {
        'bankName': bankName,
        'totalBalance': totalBalance,
        'totalTransactions': totalTransactions,
        'cardColor': firstCard.cardColor,
        'cards': cards,
      };
    }
    
    return summaries;
  }

  // Obter cartões de um banco específico
  List<CreditCard> getCardsByBank(String bankName) {
    return _creditCards.where((card) => card.bankName == bankName).toList();
  }
}