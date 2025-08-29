import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/installment.dart';
import '../providers/installment_provider.dart';
import '../providers/date_provider.dart';
import 'add_installment_screen.dart';

class CreditCardsScreen extends StatefulWidget {
  const CreditCardsScreen({super.key});

  @override
  State<CreditCardsScreen> createState() => _CreditCardsScreenState();
}

class _CreditCardsScreenState extends State<CreditCardsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInstallments();
    });
  }

  Future<void> _loadInstallments() async {
    final provider = Provider.of<InstallmentProvider>(context, listen: false);
    final dateProvider = Provider.of<DateProvider>(context, listen: false);
    await provider.loadInstallments(month: dateProvider.selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Parcelas dos Cartões',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<InstallmentProvider, DateProvider>(
        builder: (context, provider, dateProvider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar parcelas',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: GoogleFonts.poppins(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInstallments,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Month selector and summary
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateProvider.formattedMonth,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                dateProvider.previousMonth();
                                _loadInstallments();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                dateProvider.nextMonth();
                                _loadInstallments();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_month),
                              onPressed: () => _showMonthPicker(dateProvider),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total do Mês',
                            'R\$ ${provider.currentMonthInstallments(dateProvider.selectedMonth).fold(0.0, (sum, i) => sum + i.valor).toStringAsFixed(2).replaceAll('.', ',')}',
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Parcelas',
                            '${provider.currentMonthInstallments(dateProvider.selectedMonth).length}',
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Installments list
              Expanded(
                child: _buildInstallmentsList(provider.currentMonthInstallments(dateProvider.selectedMonth), provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddInstallmentScreen(),
            ),
          );
        },
        backgroundColor: Colors.teal.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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

  Widget _buildInstallmentsList(List<Installment> installments, InstallmentProvider provider) {
    if (installments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma parcela encontrada',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione uma compra parcelada',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: installments.length,
      itemBuilder: (context, index) {
        final installment = installments[index];
        return _buildInstallmentCard(installment, provider);
      },
    );
  }

  Widget _buildInstallmentCard(Installment installment, InstallmentProvider provider) {
    final now = DateTime.now();
    final isOverdue = installment.isPending && 
        (installment.ano < now.year || (installment.ano == now.year && installment.mes < now.month));
    final isPaid = installment.isPaid;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? Colors.red.shade200 : 
                 isPaid ? Colors.green.shade200 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isOverdue ? Colors.red.shade100 :
                       isPaid ? Colors.green.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPaid ? Icons.check_circle :
                isOverdue ? Icons.warning : Icons.credit_card,
                color: isOverdue ? Colors.red.shade600 :
                       isPaid ? Colors.green.shade600 : Colors.blue.shade600,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    installment.descricao,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${installment.parcelasPagas}/${installment.parcelas}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mês: ${installment.mes}/${installment.ano}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Trace: ${installment.traceControl}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Amount and actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${installment.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green.shade600 : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showEditDialog(installment, provider),
                      icon: Icon(
                        Icons.edit,
                        color: Colors.blue.shade600,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                    IconButton(
                      onPressed: () => _showDeleteDialog(installment, provider),
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade600,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Installment installment, InstallmentProvider provider) {
    final valorController = TextEditingController(text: installment.valor.toStringAsFixed(2));
    final descricaoController = TextEditingController(text: installment.descricao);
    final parcelasController = TextEditingController(text: installment.parcelas.toString());
    final parcelasPagasController = TextEditingController(text: installment.parcelasPagas.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Editar Parcela',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descricaoController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valorController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: parcelasController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Total Parcelas',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: parcelasPagasController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Parcelas Pagas',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final valor = double.tryParse(valorController.text);
              final parcelas = int.tryParse(parcelasController.text);
              final parcelasPagas = int.tryParse(parcelasPagasController.text);
              
              if (valor != null && parcelas != null && parcelasPagas != null) {
                final updatedInstallment = installment.copyWith(
                  valor: valor,
                  descricao: descricaoController.text,
                  parcelas: parcelas,
                  parcelasPagas: parcelasPagas,
                );
                await provider.updateInstallment(updatedInstallment);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Installment installment, InstallmentProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Deletar Parcela',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tem certeza que deseja deletar a parcela "${installment.descricao}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteInstallment(installment.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deletar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(DateProvider dateProvider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateProvider.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      dateProvider.setSelectedMonth(DateTime(picked.year, picked.month));
      _loadInstallments();
    }
  }
}
