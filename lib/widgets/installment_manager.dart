import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/finance.dart';

class InstallmentManager extends StatefulWidget {
  final Finance finance;
  final Function(List<int> parcelasQuitadas, double? valorDesconto, double? valorPago) onUpdate;

  const InstallmentManager({
    super.key,
    required this.finance,
    required this.onUpdate,
  });

  @override
  State<InstallmentManager> createState() => _InstallmentManagerState();
}

class _InstallmentManagerState extends State<InstallmentManager> {
  late List<int> _selectedParcelas;
  final _valorDescontoController = TextEditingController();
  final _valorPagoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedParcelas = List.from(widget.finance.parcelasQuitadas ?? []);
    _valorDescontoController.text = widget.finance.valorDesconto?.toStringAsFixed(2) ?? '';
    _valorPagoController.text = widget.finance.valorPago?.toStringAsFixed(2) ?? '';
  }

  @override
  void dispose() {
    _valorDescontoController.dispose();
    _valorPagoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Gerenciar Parcelas',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.finance.tipo} - ${_selectedParcelas.length}/${widget.finance.quantidadeParcelas ?? 0} parcelas pagas',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          _buildInstallmentGrid(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildValueField('Total Desconto', _valorDescontoController)),
              const SizedBox(width: 16),
              Expanded(child: _buildValueField('Valor Pago', _valorPagoController)),
            ],
          ),
          const SizedBox(height: 24),
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
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _updateInstallments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Atualizar',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentGrid() {
    final totalParcelas = widget.finance.quantidadeParcelas ?? 0;
    if (totalParcelas == 0) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Nenhuma parcela definida',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(totalParcelas, (index) {
            final parcelaNumber = index + 1;
            final isPaid = _selectedParcelas.contains(parcelaNumber);
            
            return GestureDetector(
              onTap: () => _toggleParcela(parcelaNumber),
              child: Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: isPaid ? Colors.indigo.shade600 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPaid ? Colors.indigo.shade600 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    parcelaNumber.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPaid ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildValueField(String label, TextEditingController controller) {
    return Column(
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
        ),
      ],
    );
  }

  void _toggleParcela(int parcelaNumber) {
    setState(() {
      if (_selectedParcelas.contains(parcelaNumber)) {
        _selectedParcelas.remove(parcelaNumber);
      } else {
        _selectedParcelas.add(parcelaNumber);
      }
      _selectedParcelas.sort();
    });
  }

  void _updateInstallments() {
    final valorDesconto = double.tryParse(_valorDescontoController.text);
    final valorPago = double.tryParse(_valorPagoController.text);
    
    widget.onUpdate(_selectedParcelas, valorDesconto, valorPago);
    Navigator.pop(context);
  }
}

// Função helper para mostrar o dialog
void showInstallmentManager(BuildContext context, Finance finance, Function(List<int>, double?, double?) onUpdate) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InstallmentManager(
        finance: finance,
        onUpdate: onUpdate,
      ),
    ),
  );
}
