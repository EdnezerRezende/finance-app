import 'dart:typed_data';
import 'dart:math';
import 'package:csv/csv.dart';
import '../models/credit_card_master.dart';
import '../models/credit_card_transaction.dart';

class BankIntegrationService {
  static const Map<String, BankConfig> bankConfigs = {
    'nubank': BankConfig(
      name: 'Nubank',
      csvDateFormat: 'yyyy-MM-dd',
      csvColumns: {
        'date': 0,
        'description': 1,
        'amount': 2,
      },
      apiEndpoint: null,
    ),
    'mercadopago': BankConfig(
      name: 'Mercado Pago',
      csvDateFormat: 'yyyy-MM-dd',
      csvColumns: {
        'date': 0,
        'description': 1,
        'amount': 2,
      },
      apiEndpoint: 'https://api.mercadopago.com',
    ),
    'brb': BankConfig(
      name: 'BRB',
      csvDateFormat: 'yyyy-MM-dd',
      csvColumns: {
        'date': 0,
        'description': 1,
        'amount': 2,
      },
      apiEndpoint: null,
    ),
    'itau': BankConfig(
      name: 'Itaú',
      csvDateFormat: 'yyyy-MM-dd',
      csvColumns: {
        'date': 0,
        'description': 1,
        'amount': 2,
      },
      apiEndpoint: null,
    ),
    'bradesco': BankConfig(
      name: 'Bradesco',
      csvDateFormat: 'yyyy-MM-dd',
      csvColumns: {
        'date': 0,
        'description': 1,
        'amount': 2,
      },
      apiEndpoint: null,
    ),
  };

  static Future<List<CreditCardTransaction>> importFromCSV(
    Uint8List fileBytes,
    CreditCardMaster targetCard,
    String userId, {
    int? referenceMonth,
    int? referenceYear,
  }) async {
    // Mapear nome do banco para código
    final bankCode = _getBankCodeFromName(targetCard.bankName);
    final config = bankConfigs[bankCode];
    if (config == null) {
      throw Exception('Banco não suportado: ${targetCard.bankName}');
    }

    final csvContent = String.fromCharCodes(fileBytes);
    print('CSV Content preview: ${csvContent.substring(0, min(200, csvContent.length))}');
    
    // Normalizar quebras de linha - converter \r\n e \r para \n
    final normalizedContent = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    
    // Verificar se o CSV tem quebras de linha corretas
    final lines = normalizedContent.split('\n').where((line) => line.trim().isNotEmpty).toList();
    print('Total lines in CSV after normalization: ${lines.length}');
    
    // Se ainda temos apenas uma linha, tentar parsing manual
    if (lines.length == 1) {
      print('CSV appears to be a single line, attempting manual parsing...');
      return _parseCSVManually(lines[0], config, userId, targetCard, referenceMonth, referenceYear);
    }
    
    // Se temos muitas linhas mas o CSV parser retorna apenas 1 row, usar parsing linha por linha
    final rows = const CsvToListConverter().convert(normalizedContent);
    if (rows.length == 1 && lines.length > 2) {
      print('CSV parser failed, using line-by-line parsing...');
      return _parseCSVLineByLine(lines, config, userId, targetCard, referenceMonth, referenceYear);
    }
    print('Total rows in CSV: ${rows.length}');
    
    if (rows.isEmpty) {
      throw Exception('CSV vazio ou formato inválido');
    }
    
    print('First row (headers): ${rows[0]}');
    
    final transactions = <CreditCardTransaction>[];
    
    // Skip header row (start from index 1)
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      print('Processing row $i: $row (length: ${row.length})');
      
      // Skip empty rows
      if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
        print('Skipping empty row $i');
        continue;
      }
      
      try {
        final transaction = _parseTransactionFromRow(row, config, userId, targetCard, referenceMonth, referenceYear);
        transactions.add(transaction);
        print('Successfully parsed transaction: ${transaction.description}');
      } catch (e) {
        print('Erro ao processar linha $i: $e');
        print('Row data: $row');
      }
    }
    
    print('Total transactions parsed: ${transactions.length}');
    return transactions;
  }

  static CreditCardTransaction _parseTransactionFromRow(
    List<dynamic> row,
    BankConfig config,
    String userId,
    CreditCardMaster targetCard,
    int? referenceMonth,
    int? referenceYear,
  ) {
    print('_parseCreditCardFromRow called with row length: ${row.length}, config columns: ${config.csvColumns}');
    
    if (row.length < 3) {
      throw Exception('Row must have at least 3 columns (date, description, amount)');
    }

    try {
      final dateStr = row[config.csvColumns['date']!].toString().trim();
      final description = row[config.csvColumns['description']!].toString().trim();
      final amountStr = row[config.csvColumns['amount']!].toString().trim();
      
      print('Parsing: date="$dateStr", description="$description", amount="$amountStr"');
      
      DateTime date;
      try {
        date = DateTime.parse(dateStr);
      } catch (e) {
        print('Failed to parse date "$dateStr" with DateTime.parse, trying other formats');
        // Try different date formats
        if (dateStr.contains('/')) {
          // Try dd/MM/yyyy format
          final parts = dateStr.split('/');
          if (parts.length == 3) {
            date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          } else {
            throw Exception('Unsupported date format: $dateStr');
          }
        } else {
          throw Exception('Unsupported date format: $dateStr');
        }
      }
      
      final cleanAmountStr = amountStr.replaceAll(',', '.');
      final amount = double.parse(cleanAmountStr);
      
      print('Parsed successfully: date=$date, amount=$amount');
      
      // Valores negativos são pagamentos/créditos, positivos são gastos
      final isPayment = amount < 0;
      
      // Criar transação vinculada ao cartão específico
      return CreditCardTransaction(
        id: '', // Será gerado pelo banco
        creditCardId: targetCard.id,
        description: '${isPayment ? 'PAGAMENTO: ' : ''}$description',
        amount: amount, // Manter sinal original (negativo para pagamentos)
        transactionDate: date,
        referenceMonth: referenceMonth ?? date.month,
        referenceYear: referenceYear ?? date.year,
        isPayment: isPayment,
      );
    } catch (e) {
      print('Error parsing row: $e');
      print('Row content: $row');
      rethrow;
    }
  }

  static String _getBankCodeFromName(String bankName) {
    switch (bankName.toLowerCase()) {
      case 'nubank':
        return 'nubank';
      case 'mercado pago':
        return 'mercadopago';
      case 'brb':
        return 'brb';
      case 'itaú':
      case 'itau':
        return 'itau';
      case 'bradesco':
        return 'bradesco';
      default:
        return 'nubank'; // Padrão
    }
  }

  static Map<String, dynamic> _getBankInfo(String bankCode) {
    switch (bankCode) {
      case 'nubank':
        return {
          'name': 'Nubank',
          'closingDay': 15,
          'dueDay': 10,
          'color': '#8A05BE',
        };
      case 'mercadopago':
        return {
          'name': 'Mercado Pago',
          'closingDay': 1,
          'dueDay': 15,
          'color': '#00B1EA',
        };
      case 'brb':
        return {
          'name': 'BRB',
          'closingDay': 5,
          'dueDay': 25,
          'color': '#FF6B35',
        };
      default:
        return {
          'name': 'Cartão',
          'closingDay': 1,
          'dueDay': 10,
          'color': '#2196F3',
        };
    }
  }

  static Future<List<CreditCardTransaction>> _parseCSVLineByLine(
    List<String> lines,
    BankConfig config,
    String userId,
    CreditCardMaster targetCard,
    int? referenceMonth,
    int? referenceYear,
  ) async {
    print('Line-by-line CSV parsing for ${lines.length} lines');
    
    final transactions = <CreditCardTransaction>[];
    
    // Skip header (first line)
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      try {
        // Dividir por vírgula
        final parts = line.split(',');
        if (parts.length >= 3) {
          // Limpar espaços em branco
          final cleanParts = parts.map((part) => part.trim()).toList();
          final transaction = _parseTransactionFromRow(cleanParts, config, userId, targetCard, referenceMonth, referenceYear);
          transactions.add(transaction);
          print('Parsed transaction: ${transaction.description}');
        } else {
          print('Skipping line $i: insufficient columns (${parts.length})');
        }
      } catch (e) {
        print('Erro ao processar linha $i: $e');
        print('Line content: $line');
      }
    }
    
    print('Total transactions parsed line-by-line: ${transactions.length}');
    return transactions;
  }

  static Future<List<CreditCardTransaction>> _parseCSVManually(
    String csvLine,
    BankConfig config,
    String userId,
    CreditCardMaster targetCard,
    int? referenceMonth,
    int? referenceYear,
  ) async {
    print('Manual CSV parsing for line: ${csvLine.substring(0, min(100, csvLine.length))}...');
    
    // Tentar identificar padrões de data para separar as linhas
    final datePattern = RegExp(r'\d{4}-\d{2}-\d{2}');
    final matches = datePattern.allMatches(csvLine);
    
    if (matches.length <= 1) {
      throw Exception('Não foi possível identificar múltiplas transações no CSV');
    }
    
    final transactions = <CreditCardTransaction>[];
    final matchList = matches.toList();
    
    for (int i = 0; i < matchList.length; i++) {
      try {
        final startIndex = matchList[i].start;
        final endIndex = i < matchList.length - 1 ? matchList[i + 1].start : csvLine.length;
        
        final transactionLine = csvLine.substring(startIndex, endIndex).trim();
        if (transactionLine.isEmpty) continue;
        
        // Remover vírgulas finais
        final cleanLine = transactionLine.replaceAll(RegExp(r',$'), '');
        
        // Dividir por vírgula (assumindo formato CSV simples)
        final parts = cleanLine.split(',');
        if (parts.length >= 3) {
          final transaction = _parseTransactionFromRow(parts, config, userId, targetCard, referenceMonth, referenceYear);
          transactions.add(transaction);
          print('Parsed transaction: ${transaction.description}');
        }
      } catch (e) {
        print('Erro ao processar transação $i: $e');
      }
    }
    
    print('Total transactions parsed manually: ${transactions.length}');
    return transactions;
  }

  static String _categorizeTransaction(String description) {
    final desc = description.toLowerCase();
    
    if (desc.contains('supermercado') || desc.contains('mercado')) {
      return 'Alimentação';
    } else if (desc.contains('posto') || desc.contains('combustivel')) {
      return 'Transporte';
    } else if (desc.contains('farmacia') || desc.contains('hospital')) {
      return 'Saúde';
    } else if (desc.contains('restaurante') || desc.contains('lanchonete')) {
      return 'Alimentação';
    }
    
    return 'Outros';
  }

}

class BankConfig {
  final String name;
  final String csvDateFormat;
  final Map<String, int> csvColumns;
  final String? apiEndpoint;

  const BankConfig({
    required this.name,
    required this.csvDateFormat,
    required this.csvColumns,
    this.apiEndpoint,
  });
}

