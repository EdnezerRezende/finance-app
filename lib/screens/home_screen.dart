import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/transaction_provider.dart';
import '../providers/credit_card_provider.dart';
import '../providers/installment_provider.dart';
import '../providers/ai_provider.dart';
import '../providers/date_provider.dart';
import '../providers/group_provider.dart';
import '../providers/finance_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_item.dart';
import '../widgets/credit_card_widget.dart';
import '../widgets/group_selector.dart';
import 'add_transaction_screen.dart';
import 'transactions_screen.dart';
import 'ai_advisor_screen.dart';
import 'reports_screen.dart';
import 'credit_cards_screen.dart';
import 'finances_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    
    // Carregar grupos do usuário primeiro
    await groupProvider.loadUserGroups();
    
    // Se há grupos disponíveis, selecionar o primeiro automaticamente
    if (groupProvider.userGroups.isNotEmpty && groupProvider.selectedGroupId == null) {
      groupProvider.selectGroup(groupProvider.userGroups.first.id);
    }
    
    // Configurar listeners para mudanças de grupo
    groupProvider.addListener(_onGroupChanged);
    
    // Carregar dados se há um grupo selecionado
    if (groupProvider.selectedGroupId != null) {
      await _loadData();
    }
  }

  void _onGroupChanged() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    if (groupProvider.selectedGroupId != null) {
      _updateProvidersWithGroup();
      _loadData();
    }
  }

  void _updateProvidersWithGroup() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final selectedGroupId = groupProvider.selectedGroupId;
    
    if (selectedGroupId != null) {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
      final creditCardProvider = Provider.of<CreditCardProvider>(context, listen: false);
      final installmentProvider = Provider.of<InstallmentProvider>(context, listen: false);
      
      transactionProvider.setCurrentGroup(selectedGroupId);
      financeProvider.setCurrentGroup(selectedGroupId);
      creditCardProvider.setCurrentGroup(selectedGroupId);
      installmentProvider.setCurrentGroup(selectedGroupId);
    }
  }

  Future<void> _loadData() async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final creditCardProvider = Provider.of<CreditCardProvider>(context, listen: false);
    final installmentProvider = Provider.of<InstallmentProvider>(context, listen: false);
    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    final aiProvider = Provider.of<AIProvider>(context, listen: false);
    final dateProvider = Provider.of<DateProvider>(context, listen: false);

    await Future.wait([
      transactionProvider.loadTransactions(month: dateProvider.selectedMonth),
      creditCardProvider.loadCreditCards(),
      installmentProvider.loadInstallments(month: dateProvider.selectedMonth),
      financeProvider.loadFinances(),
      aiProvider.loadRecommendations(),
    ]);

    // Gerar recomendações da IA
    await aiProvider.generateRecommendations(
      transactionProvider.transactions,
      creditCardProvider.creditCards,
    );
  }

  @override
  void dispose() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    groupProvider.removeListener(_onGroupChanged);
    super.dispose();
  }

  Future<void> _reloadTransactionsForMonth(DateTime selectedMonth) async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.loadTransactions(month: selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          _buildTransactionsTab(),
          _buildReportsTab(),
          _buildCreditCardsTab(),
          _buildFinancesTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue.shade600,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Transações',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Relatórios',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card),
              label: 'Cartões',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance),
              label: 'Financiamentos',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return Consumer2<TransactionProvider, DateProvider>(
      builder: (context, transactionProvider, dateProvider, child) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF2E7D32),
              actions: const [
                GroupSelector(),
                SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Finanças Pessoais',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2E7D32),
                        Color(0xFF1B5E20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildBalanceCard(transactionProvider, dateProvider.selectedMonth),
            ),
            SliverToBoxAdapter(
              child: _buildQuickActions(),
            ),
            SliverToBoxAdapter(
              child: _buildRecentTransactions(transactionProvider),
            ),
            SliverToBoxAdapter(
              child: _buildCreditCardsPreview(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações Rápidas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Adicionar Transação',
                  Icons.add_circle,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTransactionScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Consultar IA',
                  Icons.psychology,
                  Colors.blue,
                  () => setState(() => _currentIndex = 2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(TransactionProvider transactionProvider) {
    return Consumer<DateProvider>(
      builder: (context, dateProvider, child) {
        final recentTransactions = transactionProvider.transactions
            .where((t) => t.date.year == dateProvider.selectedMonth.year && 
                         t.date.month == dateProvider.selectedMonth.month)
            .take(5)
            .toList();

        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthSelector(dateProvider),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transações Recentes',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 1),
                    child: Text(
                      'Ver todas',
                      style: GoogleFonts.poppins(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (recentTransactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma transação encontrada',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentTransactions.map((transaction) => TransactionItem(
                  transaction: transaction,
                  onTap: () {
                    // Implementar edição de transação
                  },
                )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreditCardsPreview() {
    return Consumer2<InstallmentProvider, DateProvider>(
      builder: (context, installmentProvider, dateProvider, child) {
        final currentMonthInstallments = installmentProvider.currentMonthInstallments(dateProvider.selectedMonth);
        final totalValue = currentMonthInstallments.fold(0.0, (sum, installment) => sum + installment.valor);
        final installmentCount = currentMonthInstallments.length;

        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cartões de Crédito',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 3),
                    child: Text(
                      'Ver todos',
                      style: GoogleFonts.poppins(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (installmentCount == 0)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma parcela este mês',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total do Mês',
                        'R\$ ${totalValue.toStringAsFixed(2).replaceAll('.', ',')}',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Parcelas',
                        '$installmentCount',
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return const TransactionsScreen();
  }


  Widget _buildReportsTab() {
    return const ReportsScreen();
  }

  Widget _buildCreditCardsTab() {
    return const CreditCardsScreen();
  }

  Widget _buildFinancesTab() {
    return const FinancesScreen();
  }

  Widget _buildBalanceCard(TransactionProvider provider, DateTime selectedMonth) {
    final monthIncomes = provider.getIncomesByMonth(selectedMonth);
    final monthExpenses = provider.getExpensesByMonth(selectedMonth);
    
    final totalIncomes = monthIncomes.fold(0.0, (sum, t) => sum + t.amount);
    final totalExpenses = monthExpenses.fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncomes - totalExpenses;

    return BalanceCard(
      income: totalIncomes,
      expenses: totalExpenses,
      balance: balance,
    );
  }

  Widget _buildMonthSelector(DateProvider dateProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateProvider.formattedMonth,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  dateProvider.previousMonth();
                  _reloadTransactionsForMonth(dateProvider.selectedMonth);
                },
                icon: Icon(Icons.chevron_left, color: Colors.blue.shade600),
              ),
              IconButton(
                onPressed: () {
                  dateProvider.nextMonth();
                  _reloadTransactionsForMonth(dateProvider.selectedMonth);
                },
                icon: Icon(Icons.chevron_right, color: Colors.blue.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

} 