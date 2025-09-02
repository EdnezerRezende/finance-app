import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/transaction_provider.dart';
import '../providers/date_provider.dart';
import '../models/transaction.dart';
import '../widgets/transaction_item.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, DateProvider>(
      builder: (context, transactionProvider, dateProvider, child) {
        final expenses = transactionProvider.transactions
            .where((t) => t.type == "DESPESA" && 
                         t.date.year == dateProvider.selectedMonth.year && 
                         t.date.month == dateProvider.selectedMonth.month)
            .toList();
        final incomes = transactionProvider.transactions
            .where((t) => t.type == "ENTRADA" && 
                         t.date.year == dateProvider.selectedMonth.year && 
                         t.date.month == dateProvider.selectedMonth.month)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Transações',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () => _showMonthPicker(dateProvider),
                icon: const Icon(Icons.calendar_today),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(),
              tabs: [
                Tab(
                  icon: Icon(Icons.trending_down),
                  text: 'Despesas (${expenses.length})',
                ),
                Tab(
                  icon: Icon(Icons.trending_up),
                  text: 'Entradas (${incomes.length})',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildExpensesTab(expenses, transactionProvider, dateProvider.selectedMonth),
              _buildIncomesTab(incomes, transactionProvider, dateProvider.selectedMonth),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTransactionScreen(),
              ),
            ),
            backgroundColor: Colors.blue.shade600,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab(List<Transaction> expenses, TransactionProvider provider, DateTime selectedMonth) {
    final monthExpenses = provider.getExpensesByMonth(selectedMonth);
    
    if (monthExpenses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.trending_down,
        title: 'Nenhuma despesa encontrada',
        subtitle: 'Adicione sua primeira despesa!',
        color: Colors.red.shade400,
      );
    }

    final totalExpenses = monthExpenses.fold<double>(0, (sum, t) => sum + t.amount);

    return Column(
      children: [
        // Resumo das despesas
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.red.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_down, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Total de Despesas',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ ${totalExpenses.toStringAsFixed(2).replaceAll('.', ',')}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Lista de despesas
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: monthExpenses.length,
            itemBuilder: (context, index) {
              final transaction = monthExpenses[index];
              return TransactionItem(
                transaction: transaction,
                onDelete: () => provider.deleteTransaction(transaction.id),
                onTogglePayment: () => provider.togglePaymentStatus(transaction.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIncomesTab(List<Transaction> incomes, TransactionProvider provider, DateTime selectedMonth) {
    final monthIncomes = provider.getIncomesByMonth(selectedMonth);
    
    if (monthIncomes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.trending_up,
        title: 'Nenhuma entrada encontrada',
        subtitle: 'Adicione sua primeira entrada!',
        color: Colors.green.shade400,
      );
    }

    final totalIncomes = monthIncomes.fold<double>(0, (sum, t) => sum + t.amount);

    return Column(
      children: [
        // Resumo das entradas
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Total de Entradas',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ ${totalIncomes.toStringAsFixed(2).replaceAll('.', ',')}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Lista de entradas
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: monthIncomes.length,
            itemBuilder: (context, index) {
              final transaction = monthIncomes[index];
              return TransactionItem(
                transaction: transaction,
                onDelete: () => provider.deleteTransaction(transaction.id),
                onTogglePayment: () => provider.togglePaymentStatus(transaction.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTransactionScreen(),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(
              'Adicionar Transação',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(DateProvider dateProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
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
                onPressed: dateProvider.previousMonth,
                icon: Icon(Icons.chevron_left, color: Colors.blue.shade600),
              ),
              IconButton(
                onPressed: dateProvider.nextMonth,
                icon: Icon(Icons.chevron_right, color: Colors.blue.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(DateProvider dateProvider) {
    showDatePicker(
      context: context,
      initialDate: dateProvider.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      initialDatePickerMode: DatePickerMode.year,
    ).then((date) {
      if (date != null) {
        dateProvider.setSelectedMonth(DateTime(date.year, date.month));
        _reloadTransactionsForMonth(dateProvider.selectedMonth);
      }
    });
  }

  Future<void> _reloadTransactionsForMonth(DateTime selectedMonth) async {
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.loadTransactions(month: selectedMonth);
  }
}
