import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/credit_card_master_provider.dart';
import '../providers/credit_card_transaction_provider.dart';
import '../providers/group_provider.dart';
import '../models/credit_card_master.dart';
import '../models/credit_card_transaction.dart';

class CreditCardTransactionsScreen extends StatefulWidget {
  final String? initialCardId;
  
  const CreditCardTransactionsScreen({
    super.key,
    this.initialCardId,
  });

  @override
  State<CreditCardTransactionsScreen> createState() => _CreditCardTransactionsScreenState();
}

class _CreditCardTransactionsScreenState extends State<CreditCardTransactionsScreen> with SingleTickerProviderStateMixin {
  String? _selectedCardId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  late TabController _tabController;
  
  // Índices das abas
  static const int _allTabIndex = 0;
  static const int _expensesTabIndex = 1;
  static const int _incomesTabIndex = 2;

  @override
  void initState() {
    super.initState();
    _selectedCardId = widget.initialCardId;
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final creditCardMasterProvider = Provider.of<CreditCardMasterProvider>(context, listen: false);
    final creditCardTransactionProvider = Provider.of<CreditCardTransactionProvider>(context, listen: false);
    
    if (groupProvider.selectedGroupId != null) {
      creditCardMasterProvider.setCurrentGroup(groupProvider.selectedGroupId!);
      creditCardTransactionProvider.setCurrentGroup(groupProvider.selectedGroupId!);
    }
    
    await creditCardMasterProvider.loadCards();
    await _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    
    final creditCardTransactionProvider = Provider.of<CreditCardTransactionProvider>(context, listen: false);
    await creditCardTransactionProvider.loadTransactions(
      month: _selectedMonth,
      year: _selectedYear,
      cardId: _selectedCardId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transações do Cartão',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            const SizedBox(height: 20),
            _buildTransactionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            
            // Seletor de Cartão
            Consumer<CreditCardMasterProvider>(
              builder: (context, provider, child) {
                final cards = provider.cards;
                
                return DropdownButtonFormField<String>(
                  value: _selectedCardId,
                  decoration: InputDecoration(
                    labelText: 'Cartão',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos os cartões'),
                    ),
                    ...cards.map((card) {
                      return DropdownMenuItem(
                        value: card.id,
                        child: IntrinsicWidth(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 20,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(card.cardColor.replaceAll('#', '0xFF'))),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${card.name} (${card.cardNumberMasked})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCardId = value;
                    });
                    _loadTransactions();
                  },
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Seletores de Mês e Ano
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    decoration: InputDecoration(
                      labelText: 'Mês',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(12, (index) {
                      final month = index + 1;
                      final monthNames = [
                        'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
                        'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
                      ];
                      return DropdownMenuItem(
                        value: month,
                        child: Text(monthNames[index]),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMonth = value;
                        });
                        _loadTransactions();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: InputDecoration(
                      labelText: 'Ano',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - 2 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedYear = value;
                        });
                        _loadTransactions();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Consumer<CreditCardTransactionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        // Filtrar transações com base na aba selecionada
        List<CreditCardTransaction> filteredTransactions = [];
        if (_tabController.index == _allTabIndex) {
          filteredTransactions = provider.transactions;
        } else if (_tabController.index == _expensesTabIndex) {
          filteredTransactions = provider.transactions.where((t) => !t.isPayment).toList();
        } else if (_tabController.index == _incomesTabIndex) {
          filteredTransactions = provider.transactions.where((t) => t.isPayment).toList();
        }

        if (provider.error != null) {
          return Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade600,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Erro ao carregar transações',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.error!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final transactions = provider.transactions;
        
        if (transactions.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.grey.shade400,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma transação encontrada',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Importe dados do seu cartão para visualizar as transações',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Agrupar transações por cartão
        final transactionsByCard = <String, List<CreditCardTransaction>>{};
        for (final transaction in filteredTransactions) {
          if (!transactionsByCard.containsKey(transaction.creditCardId)) {
            transactionsByCard[transaction.creditCardId] = [];
          }
          transactionsByCard[transaction.creditCardId]!.add(transaction);
        }

        return Consumer<CreditCardMasterProvider>(
          builder: (context, cardProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Abas de navegação
                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.blue.shade600,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.blue.shade600,
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        onTap: (index) {
                          setState(() {}); // Força a reconstrução da tela
                        },
                        tabs: const [
                          Tab(text: 'Todas'),
                          Tab(text: 'Saídas'),
                          Tab(text: 'Entradas'),
                        ],
                      ),
                      // Resumo
                      _buildSummary(filteredTransactions),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Transações por cartão
                ...transactionsByCard.entries.map((entry) {
                  final cardId = entry.key;
                  final cardTransactions = entry.value;
                  final card = cardProvider.cards.firstWhere(
                    (c) => c.id == cardId,
                    orElse: () => CreditCardMaster(
                      id: cardId,
                      name: 'Cartão Desconhecido',
                      cardNumberMasked: '**** **** **** ****',
                      bankName: 'Desconhecido',
                      closingDay: 1,
                      dueDay: 10,
                    ),
                  );
                  
                  return _buildCardTransactions(card, cardTransactions);
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummary(List<CreditCardTransaction> transactions) {
    final totalTransactions = transactions.length;
    final totalAmount = transactions.fold<double>(0, (sum, t) => sum + t.amount.abs());
    final totalPayments = transactions.where((t) => t.isPayment).fold<double>(0, (sum, t) => sum + t.amount.abs());
    final totalExpenses = transactions.where((t) => !t.isPayment).fold<double>(0, (sum, t) => sum + t.amount.abs());

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo do Período',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Transações',
                        totalTransactions.toString(),
                        Icons.receipt_long,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Saídas',
                        'R\$ ${totalExpenses.toStringAsFixed(2)}',
                        Icons.trending_up,
                        Colors.red,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Entradas',
                        'R\$ ${totalPayments.toStringAsFixed(2)}',
                        Icons.trending_down,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                if (totalTransactions == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _tabController.index == _allTabIndex 
                          ? 'Nenhuma transação encontrada' 
                          : _tabController.index == _expensesTabIndex 
                              ? 'Nenhuma saída encontrada' 
                              : 'Nenhuma entrada encontrada',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCardTransactions(CreditCardMaster card, List<CreditCardTransaction> transactions) {
    // Ordenar transações por data (mais recente primeiro)
    transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    
    final cardTotal = transactions.fold<double>(0, (sum, t) => sum + t.amount);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do cartão
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(int.parse(card.cardColor.replaceAll('#', '0xFF'))).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(int.parse(card.cardColor.replaceAll('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        '${card.bankName} • ${card.cardNumberMasked}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${transactions.length} transações',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'R\$ ${cardTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cardTotal >= 0 ? Colors.red.shade600 : Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de transações
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionItem(transaction);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(CreditCardTransaction transaction) {
    final isPayment = transaction.isPayment;
    final color = isPayment ? Colors.green.shade600 : Colors.red.shade600;
    final icon = isPayment ? Icons.trending_down : Icons.trending_up;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        transaction.description,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
      subtitle: Text(
        '${transaction.transactionDate.day.toString().padLeft(2, '0')}/${transaction.transactionDate.month.toString().padLeft(2, '0')}/${transaction.transactionDate.year}',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Text(
        '${isPayment ? '-' : '+'}R\$ ${transaction.amount.abs().toStringAsFixed(2)}',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
