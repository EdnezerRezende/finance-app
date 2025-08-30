import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formatador de moeda brasileira (Real) para campos de entrada
class BrazilianCurrencyInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static final NumberFormat _numberFormatter = NumberFormat('#,##0.00', 'pt_BR');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove todos os caracteres não numéricos
    String numericString = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (numericString.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Converte para double (centavos para reais)
    double value = double.parse(numericString) / 100;
    
    // Formata o valor
    String formattedValue = _numberFormatter.format(value);
    
    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }

  /// Converte o texto formatado para double
  static double? parseValue(String formattedText) {
    if (formattedText.isEmpty) return null;
    
    // Remove formatação e converte para double
    String numericString = formattedText.replaceAll(RegExp(r'[^\d,]'), '');
    numericString = numericString.replaceAll(',', '.');
    
    return double.tryParse(numericString);
  }

  /// Formata um double para exibição com símbolo da moeda
  static String formatCurrency(double value) {
    return _formatter.format(value);
  }

  /// Formata um double para exibição sem símbolo da moeda
  static String formatValue(double value) {
    return _numberFormatter.format(value);
  }
}

/// Widget customizado para campo de entrada de moeda
class CurrencyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final bool enabled;
  final Function(double?)? onChanged;
  final String? Function(String?)? validator;
  final bool showCurrencySymbol;

  const CurrencyTextField({
    Key? key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.showCurrencySymbol = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [BrazilianCurrencyInputFormatter()],
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText ?? '0,00',
        prefixText: showCurrencySymbol ? 'R\$ ' : null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
      onChanged: (value) {
        if (onChanged != null) {
          final parsedValue = BrazilianCurrencyInputFormatter.parseValue(value);
          onChanged!(parsedValue);
        }
      },
    );
  }
}
