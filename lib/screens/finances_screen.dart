import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/finance.dart';
import '../providers/finance_provider.dart';
import '../widgets/installment_manager.dart';
import '../utils/dialog_utils.dart';
import 'add_finance_screen.dart';

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FinanceProvider>(context, listen: false).loadFinances();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Financiamentos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Consórcios'),
            Tab(text: 'Empréstimos'),
            Tab(text: 'Financiamentos'),
          ],
        ),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, financeProvider, child) {
          if (financeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (financeProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar financiamentos',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    financeProvider.error!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => financeProvider.loadFinances(),
                    child: Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildSummaryCards(financeProvider),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFinancesList(financeProvider.finances, financeProvider),
                    _buildFinancesList(financeProvider.getFinancesByType(FinanceType.consorcio), financeProvider),
                    _buildFinancesList(financeProvider.getFinancesByType(FinanceType.emprestimo), financeProvider),
                    _buildFinancesList(financeProvider.getFinancesByType(FinanceType.financiamento), financeProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "finances_fab",
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddFinanceScreen(),
          ),
        ),
        backgroundColor: Colors.indigo.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCards(FinanceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Financiado',
              'R\$ ${provider.totalValorFinanciado.toStringAsFixed(2)}',
              Icons.account_balance,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Saldo Devedor',
              'R\$ ${provider.totalSaldoDevedor.toStringAsFixed(2)}',
              Icons.trending_down,
              Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Progresso',
              '${provider.percentualGeralPago.toStringAsFixed(1)}%',
              Icons.pie_chart,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancesList(List<Finance> finances, FinanceProvider provider) {
    if (finances.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: finances.length,
      itemBuilder: (context, index) {
        final finance = finances[index];
        return _buildFinanceCard(finance, provider);
      },
    );
  }

  Widget _buildFinanceCard(Finance finance, FinanceProvider provider) {
    final progressColor = finance.percentualPago >= 75 
        ? Colors.green 
        : finance.percentualPago >= 50 
            ? Colors.orange 
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  finance.tipo,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, finance, provider),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'parcelas',
                    child: Row(
                      children: [
                        Icon(Icons.payment, size: 18, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        Text('Gerenciar Parcelas'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Text('Excluir'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Valor Total', 'R\$ ${finance.valorTotal?.toStringAsFixed(2) ?? "0,00"}'),
              ),
              Expanded(
                child: _buildInfoItem('Saldo Devedor', 'R\$ ${finance.saldoDevedor?.toStringAsFixed(2) ?? "0,00"}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Parcelas Pagas', '${finance.parcelasPagas}/${finance.quantidadeParcelas ?? 0}'),
              ),
              Expanded(
                child: _buildInfoItem('Valor Pago', 'R\$ ${finance.valorPago?.toStringAsFixed(2) ?? "0,00"}'),
              ),
            ],
          ),
          if (finance.valorDesconto != null && finance.valorDesconto! > 0) ...[
            const SizedBox(height: 12),
            _buildInfoItem('Descontos Obtidos', 'R\$ ${finance.valorDesconto!.toStringAsFixed(2)}'),
          ],
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progresso',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '${finance.percentualPago.toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: finance.percentualPago / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
            ],
          ),
          if (finance.isQuitado) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Quitado',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum financiamento encontrado',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione seu primeiro financiamento!',
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
                builder: (context) => const AddFinanceScreen(),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(
              'Adicionar Financiamento',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
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

  void _handleMenuAction(String action, Finance finance, FinanceProvider provider) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddFinanceScreen(finance: finance),
          ),
        );
        break;
      case 'parcelas':
        showInstallmentManager(
          context,
          finance,
          (parcelas, desconto, valorPago) async {
            await provider.updateParcelas(finance.id, parcelas, desconto, valorPago);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Parcelas atualizadas com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
        break;
      case 'delete':
        _showDeleteConfirmation(finance, provider);
        break;
    }
  }

  Future<void> _showDeleteConfirmation(Finance finance, FinanceProvider provider) async {
    final confirmed = await DialogUtils.showDeleteConfirmationDialog(
      context: context,
      title: 'Excluir Registro',
      message: 'Tem certeza que deseja excluir "${finance.tipo}"?\n\nEsta ação não pode ser desfeita.',
    );

    if (confirmed) {
      provider.deleteFinance(finance.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro excluído com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
