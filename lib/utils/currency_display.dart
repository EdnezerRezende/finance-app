import 'package:intl/intl.dart';

/// Utilitários para formatação e exibição de valores monetários
class CurrencyDisplay {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrencyFormatter = NumberFormat.compactCurrency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  /// Formata um valor para exibição com símbolo da moeda
  /// Exemplo: 1000.50 -> "R\$ 1.000,50"
  static String formatCurrency(double value) {
    return _currencyFormatter.format(value);
  }

  /// Formata um valor para exibição compacta com símbolo da moeda
  /// Exemplo: 1000000.0 -> "R\$ 1 mi"
  static String formatCompactCurrency(double value) {
    return _compactCurrencyFormatter.format(value);
  }

  /// Formata um valor para exibição sem símbolo da moeda
  /// Exemplo: 1000.50 -> "1.000,50"
  static String formatValue(double value) {
    return NumberFormat('#,##0.00', 'pt_BR').format(value);
  }

  /// Formata um valor para exibição com cor baseada no tipo (positivo/negativo)
  static String formatWithSign(double value) {
    final formatted = formatCurrency(value.abs());
    return value >= 0 ? '+$formatted' : '-$formatted';
  }

  /// Retorna a cor apropriada para um valor (verde para positivo, vermelho para negativo)
  static int getColorForValue(double value) {
    if (value > 0) return 0xFF4CAF50; // Verde
    if (value < 0) return 0xFFF44336; // Vermelho
    return 0xFF757575; // Cinza para zero
  }

  /// Formata percentual
  /// Exemplo: 0.15 -> "15%"
  static String formatPercentage(double value) {
    return NumberFormat.percentPattern('pt_BR').format(value);
  }

  /// Formata um valor nullable, retornando string vazia se for null
  static String formatNullableCurrency(double? value) {
    return value != null ? formatCurrency(value) : '';
  }

  /// Formata um valor nullable sem símbolo, retornando string vazia se for null
  static String formatNullableValue(double? value) {
    return value != null ? formatValue(value) : '';
  }
}
