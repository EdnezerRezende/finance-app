import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_recommendation.dart';
import '../models/transaction.dart';
import '../models/credit_card.dart';

class AIProvider with ChangeNotifier {
  List<AIRecommendation> _recommendations = [];
  List<Map<String, String>> _chatHistory = [];
  static const String _storageKey = 'ai_recommendations';
  static const String _chatStorageKey = 'ai_chat_history';

  List<AIRecommendation> get recommendations => _recommendations;
  List<Map<String, String>> get chatHistory => _chatHistory;
  List<AIRecommendation> get unreadRecommendations => 
      _recommendations.where((r) => !r.isRead).toList();

  Future<void> loadRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    final recommendationsJson = prefs.getStringList(_storageKey) ?? [];
    final chatHistoryJson = prefs.getStringList(_chatStorageKey) ?? [];
    
    _recommendations = recommendationsJson
        .map((json) => AIRecommendation.fromJson(jsonDecode(json)))
        .toList();
    
    _chatHistory = chatHistoryJson
        .map((json) => Map<String, String>.from(jsonDecode(json)))
        .toList();
    
    notifyListeners();
  }

  Future<void> askQuestion(String question) async {
    // Simular resposta da IA
    final answer = _generateAIResponse(question);
    
    _chatHistory.add({
      'question': question,
      'answer': answer,
    });
    
    await _saveChatHistory();
    notifyListeners();
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final chatHistoryJson = _chatHistory
        .map((chat) => jsonEncode(chat))
        .toList();
    
    await prefs.setStringList(_chatStorageKey, chatHistoryJson);
  }

  String _generateAIResponse(String question) {
    final lowerQuestion = question.toLowerCase();
    
    if (lowerQuestion.contains('economizar') || lowerQuestion.contains('poupar')) {
      return 'Para economizar mais, recomendo: 1) Revise seus gastos mensais e identifique onde pode reduzir; 2) Estabeleça metas de economia; 3) Considere alternativas mais baratas para serviços que usa regularmente.';
    } else if (lowerQuestion.contains('investir') || lowerQuestion.contains('investimento')) {
      return 'Para começar a investir: 1) Mantenha uma reserva de emergência; 2) Estude sobre diferentes tipos de investimento; 3) Comece com investimentos de baixo risco como Tesouro Direto; 4) Diversifique sua carteira gradualmente.';
    } else if (lowerQuestion.contains('cartão') || lowerQuestion.contains('crédito')) {
      return 'Para usar o cartão de crédito de forma inteligente: 1) Pague sempre o valor total da fatura; 2) Mantenha o uso abaixo de 30% do limite; 3) Use para compras planejadas, não impulsos; 4) Monitore gastos regularmente.';
    } else if (lowerQuestion.contains('orçamento') || lowerQuestion.contains('planejamento')) {
      return 'Para criar um bom orçamento: 1) Liste todas suas receitas e despesas; 2) Categorize os gastos; 3) Defina limites para cada categoria; 4) Acompanhe mensalmente e ajuste quando necessário.';
    } else {
      return 'Essa é uma ótima pergunta sobre finanças! Baseado nos seus dados, recomendo que você: 1) Monitore seus gastos regularmente; 2) Estabeleça metas financeiras claras; 3) Busque sempre equilibrar receitas e despesas. Se tiver dúvidas específicas, posso ajudar com mais detalhes!';
    }
  }

  Future<void> saveRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    final recommendationsJson = _recommendations
        .map((r) => jsonEncode(r.toJson()))
        .toList();
    
    await prefs.setStringList(_storageKey, recommendationsJson);
  }

  Future<void> addRecommendation(AIRecommendation recommendation) async {
    _recommendations.add(recommendation);
    await saveRecommendations();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _recommendations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _recommendations[index] = _recommendations[index].copyWith(isRead: true);
      await saveRecommendations();
      notifyListeners();
    }
  }

  Future<void> deleteRecommendation(String id) async {
    _recommendations.removeWhere((r) => r.id == id);
    await saveRecommendations();
    notifyListeners();
  }

  // Método para gerar recomendações baseadas nos dados
  Future<void> generateRecommendations(
    List<Transaction> transactions,
    List<CreditCard> creditCards,
  ) async {
    final recommendations = <AIRecommendation>[];
    
    // Análise de gastos por categoria
    final categoryTotals = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.isExpense) {
        categoryTotals[transaction.category] = 
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }

    // Recomendação para redução de gastos em categorias com alto gasto
    final highSpendingCategories = categoryTotals.entries
        .where((entry) => entry.value > 1000)
        .toList();
    
    for (final entry in highSpendingCategories) {
      final categoryName = entry.key;
      recommendations.add(AIRecommendation(
        title: 'Reduzir gastos em $categoryName',
        description: 'Você gastou R\$ ${entry.value.toStringAsFixed(2)} em $categoryName este mês. Considere estabelecer um limite para esta categoria.',
        type: RecommendationType.expenseReduction,
        potentialSavings: entry.value * 0.2,
        actions: [
          'Defina um orçamento mensal para $categoryName',
          'Procure alternativas mais econômicas',
          'Evite compras por impulso nesta categoria',
        ],
        createdAt: DateTime.now(),
      ));
    }

    // Análise de cartões de crédito
    final highUsageCards = creditCards.where((card) => card.usagePercentage > 70).toList();
    for (final card in highUsageCards) {
      recommendations.add(AIRecommendation(
        title: 'Atenção ao cartão ${card.name}',
        description: 'Seu cartão ${card.name} está com ${card.usagePercentage.toStringAsFixed(1)}% de utilização. Considere reduzir gastos ou pagar parte da fatura.',
        type: RecommendationType.creditCardAdvice,
        potentialSavings: card.currentBalance * 0.1,
        actions: [
          'Evite novos gastos neste cartão',
          'Considere pagar parte da fatura antecipadamente',
          'Monitore gastos diariamente',
        ],
        createdAt: DateTime.now(),
      ));
    }

    // Recomendação de investimento se houver saldo positivo
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    if (totalIncome > totalExpenses) {
      final surplus = totalIncome - totalExpenses;
      recommendations.add(AIRecommendation(
        title: 'Oportunidade de investimento',
        description: 'Você tem um saldo positivo de R\$ ${surplus.toStringAsFixed(2)}. Considere investir parte deste valor.',
        type: RecommendationType.investment,
        potentialSavings: surplus * 0.5,
        actions: [
          'Aplique 50% do saldo em investimentos',
          'Mantenha 30% como reserva de emergência',
          'Use 20% para objetivos de curto prazo',
        ],
        createdAt: DateTime.now(),
      ));
    }

    // Adicionar novas recomendações
    for (final recommendation in recommendations) {
      await addRecommendation(recommendation);
    }
  }

} 