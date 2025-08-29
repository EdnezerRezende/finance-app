import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/finance.dart';
import '../providers/finance_provider.dart';

class AddFinanceScreen extends StatefulWidget {
  final Finance? finance;
  
  const AddFinanceScreen({super.key, this.finance});

  @override
  State<AddFinanceScreen> createState() => _AddFinanceScreenState();
}

class _AddFinanceScreenState extends State<AddFinanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorTotalController = TextEditingController();
  final _saldoDevedorController = TextEditingController();
  final _valorDescontoController = TextEditingController();
  final _valorPagoController = TextEditingController();
  final _quantidadeParcelasController = TextEditingController();
  
  FinanceType _selectedType = FinanceType.financiamento;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.finance != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final finance = widget.finance!;
    _selectedType = FinanceType.fromString(finance.tipo);
    _valorTotalController.text = finance.valorTotal?.toStringAsFixed(2) ?? '';
    _saldoDevedorController.text = finance.saldoDevedor?.toStringAsFixed(2) ?? '';
    _valorDescontoController.text = finance.valorDesconto?.toStringAsFixed(2) ?? '';
    _valorPagoController.text = finance.valorPago?.toStringAsFixed(2) ?? '';
    _quantidadeParcelasController.text = finance.quantidadeParcelas?.toString() ?? '';
  }

  @override
  void dispose() {
    _valorTotalController.dispose();
    _saldoDevedorController.dispose();
    _valorDescontoController.dispose();
    _valorPagoController.dispose();
    _quantidadeParcelasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.finance == null ? 'Novo Financiamento' : 'Editar Financiamento',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, financeProvider, child) {
          if (financeProvider.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(financeProvider.error!),
                  backgroundColor: Colors.red,
                ),
              );
              financeProvider.clearError();
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTypeSelector(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildValueField('Valor Total', _valorTotalController)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildValueField('Saldo Devedor', _saldoDevedorController)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildValueField('Total Desconto', _valorDescontoController, required: false)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildValueField('Valor Pago', _valorPagoController, required: false)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildIntegerField('Quantidade Parcelas', _quantidadeParcelasController),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cancel),
                              const SizedBox(width: 8),
                              Text(
                                'Cancelar',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveFinance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.save),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.finance == null ? 'Criar' : 'Atualizar',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeSelector() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de Financiamento',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<FinanceType>(
            value: _selectedType,
            decoration: InputDecoration(
              hintText: 'Selecione',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.indigo.shade600),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: FinanceType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type.displayName,
                  style: GoogleFonts.poppins(),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildValueField(String label, TextEditingController controller, {bool required = true}) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              hintText: '0,00',
              prefixText: 'R\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.indigo.shade600),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: required ? (value) {
              if (value == null || value.isEmpty) {
                return '$label é obrigatório';
              }
              if (double.tryParse(value) == null) {
                return 'Digite um valor válido';
              }
              return null;
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildIntegerField(String label, TextEditingController controller) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              hintText: '0',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.indigo.shade600),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '$label é obrigatório';
              }
              if (int.tryParse(value) == null) {
                return 'Digite um número válido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveFinance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);

    final finance = Finance(
      id: widget.finance?.id ?? 0,
      createdAt: widget.finance?.createdAt ?? DateTime.now(),
      tipo: _selectedType.displayName,
      valorTotal: double.tryParse(_valorTotalController.text),
      saldoDevedor: double.tryParse(_saldoDevedorController.text),
      quantidadeParcelas: int.tryParse(_quantidadeParcelasController.text),
      parcelasQuitadas: widget.finance?.parcelasQuitadas ?? [],
      valorDesconto: double.tryParse(_valorDescontoController.text),
      valorPago: double.tryParse(_valorPagoController.text),
      userId: null,
    );

    try {
      if (widget.finance == null) {
        await financeProvider.addFinance(finance);
      } else {
        await financeProvider.updateFinance(finance);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.finance == null 
                  ? 'Financiamento criado com sucesso!' 
                  : 'Financiamento atualizado com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar financiamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
