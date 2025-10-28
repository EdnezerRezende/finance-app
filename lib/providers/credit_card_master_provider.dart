import 'package:flutter/foundation.dart';
import '../models/credit_card_master.dart';
import '../services/supabase_service.dart';

class CreditCardMasterProvider extends ChangeNotifier {
  List<CreditCardMaster> _cards = [];
  bool _isLoading = false;
  String? _error;
  String? _currentGroupId;

  List<CreditCardMaster> get cards => _cards;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setCurrentGroup(String? groupId) {
    _currentGroupId = groupId;
    notifyListeners();
  }

  // Agrupar cartões por banco
  Map<String, List<CreditCardMaster>> get cardsByBank {
    final grouped = <String, List<CreditCardMaster>>{};
    for (final card in _cards) {
      if (!grouped.containsKey(card.bankName)) {
        grouped[card.bankName] = [];
      }
      grouped[card.bankName]!.add(card);
    }
    return grouped;
  }

  Future<void> loadCards() async {
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
        debugPrint('CreditCardMasterProvider: Nenhum grupo selecionado');
        return;
      }
      
      debugPrint('CreditCardMasterProvider: Carregando cartões para grupo: $_currentGroupId');
      final data = await SupabaseService.getCreditCardMasters(groupId: _currentGroupId!);
      _cards = data.map((json) => CreditCardMaster.fromSupabase(json)).toList();
    } catch (e) {
      _error = 'Erro ao carregar cartões: $e';
      debugPrint('Error loading credit card masters: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCard(CreditCardMaster card) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newCard = card.copyWith(
        groupId: _currentGroupId,
      );

      final cardData = newCard.toSupabase(includeId: false);
      debugPrint('CreditCardMasterProvider: Salvando cartão: ${newCard.name} - ${newCard.bankName}');
      debugPrint('CreditCardMasterProvider: GroupId: ${newCard.groupId}');
      
      final data = await SupabaseService.insertCreditCardMaster(cardData);
      final savedCard = CreditCardMaster.fromSupabase(data);
      
      _cards.add(savedCard);
      debugPrint('CreditCardMasterProvider: Cartão salvo com ID: ${savedCard.id}');
      debugPrint('CreditCardMasterProvider: Total de cartões: ${_cards.length}');
    } catch (e) {
      _error = 'Erro ao adicionar cartão: $e';
      debugPrint('Error adding credit card master: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCard(CreditCardMaster card) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cardData = card.toSupabase(includeId: true);
      debugPrint('CreditCardMasterProvider: Atualizando cartão');
      
      await SupabaseService.updateCreditCardMaster(card.id, cardData);
      
      final index = _cards.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        _cards[index] = card;
      }
    } catch (e) {
      _error = 'Erro ao atualizar cartão: $e';
      debugPrint('Error updating credit card master: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCard(String id) async {
    if (!SupabaseService.isLoggedIn) {
      _error = 'Usuário não autenticado';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService.deleteCreditCardMaster(id);
      _cards.removeWhere((card) => card.id == id);
    } catch (e) {
      _error = 'Erro ao excluir cartão: $e';
      debugPrint('Error deleting credit card master: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  CreditCardMaster? getCardById(String id) {
    try {
      return _cards.firstWhere((card) => card.id == id);
    } catch (e) {
      return null;
    }
  }

  List<CreditCardMaster> getCardsByBank(String bankName) {
    return _cards.where((card) => card.bankName == bankName).toList();
  }
}
