import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/credit_card_master_provider.dart';
import '../providers/credit_card_transaction_provider.dart';
import '../providers/group_provider.dart';
import '../screens/credit_card_transactions_screen.dart';
import '../screens/manage_cards_screen.dart';

class CreditCardSummaryScreen extends StatefulWidget {
  const CreditCardSummaryScreen({super.key});

  @override
  State<CreditCardSummaryScreen> createState() => _CreditCardSummaryScreenState();
}

class _CreditCardSummaryScreenState extends State<CreditCardSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCreditCards();
    });
  }

  Future<void> _loadCreditCards() async {
    if (!mounted) return;
    
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final creditCardMasterProvider = Provider.of<CreditCardMasterProvider>(context, listen: false);
    final creditCardTransactionProvider = Provider.of<CreditCardTransactionProvider>(context, listen: false);
    
    if (groupProvider.selectedGroupId != null) {
      creditCardMasterProvider.setCurrentGroup(groupProvider.selectedGroupId!);
      creditCardTransactionProvider.setCurrentGroup(groupProvider.selectedGroupId!);
    }
    
    await creditCardMasterProvider.loadCards();
    await creditCardTransactionProvider.loadTransactions(
      month: DateTime.now().month,
      year: DateTime.now().year,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cartões de Crédito',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageCardsScreen(),
                ),
              ).then((_) => _loadCreditCards());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCreditCards,
          ),
        ],
      ),
      body: Consumer2<CreditCardMasterProvider, CreditCardTransactionProvider>(
        builder: (context, cardProvider, transactionProvider, child) {
          if (cardProvider.isLoading || transactionProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            );
          }

          if (cardProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar cartões',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cardProvider.error!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final cards = cardProvider.cards;
          final transactions = transactionProvider.transactions;

          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_off,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum cartão cadastrado',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cadastre cartões para visualizar o resumo',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageCardsScreen(),
                        ),
                      ).then((_) => _loadCreditCards());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Cadastrar Cartão'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          // Agrupar por operadora
          final cardsByBank = <String, List<dynamic>>{};
          for (final card in cards) {
            if (!cardsByBank.containsKey(card.bankName)) {
              cardsByBank[card.bankName] = [];
            }
            
            // Calcular total de transações para este cartão
            final cardTransactions = transactions.where((t) => t.creditCardId == card.id).toList();
            final totalAmount = cardTransactions.fold<double>(0, (sum, t) => sum + t.amount);
            
            cardsByBank[card.bankName]!.add({
              'card': card,
              'transactions': cardTransactions,
              'totalAmount': totalAmount,
            });
          }

          return RefreshIndicator(
            onRefresh: _loadCreditCards,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cardsByBank.length,
              itemBuilder: (context, index) {
                final bankName = cardsByBank.keys.elementAt(index);
                final bankCards = cardsByBank[bankName]!;
                
                // Calcular total da operadora
                final bankTotal = bankCards.fold<double>(0, (sum, cardData) => sum + cardData['totalAmount']);
                
                return _buildBankSection(bankName, bankCards, bankTotal);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBankSection(String bankName, List<dynamic> bankCards, double bankTotal) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da operadora
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      bankName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${bankCards.length} cartão${bankCards.length > 1 ? 'ões' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'R\$ ${bankTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: bankTotal >= 0 ? Colors.red.shade600 : Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de cartões da operadora
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bankCards.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final cardData = bankCards[index];
              return _buildCardTile(cardData);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(Map<String, dynamic> cardData) {
    final card = cardData['card'];
    final transactions = cardData['transactions'] as List;
    final totalAmount = cardData['totalAmount'] as double;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 24,
        decoration: BoxDecoration(
          color: Color(int.parse(card.cardColor.replaceAll('#', '0xFF'))),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(
        card.name,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.cardNumberMasked,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            '${transactions.length} transação${transactions.length != 1 ? 'ões' : ''} este mês',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'R\$ ${totalAmount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: totalAmount >= 0 ? Colors.red.shade600 : Colors.green.shade600,
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.shade400,
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreditCardTransactionsScreen(
              initialCardId: card.id,
            ),
          ),
        );
      },
    );
  }
}
