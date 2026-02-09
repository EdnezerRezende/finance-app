import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/credit_card_master_provider.dart';
import '../providers/credit_card_transaction_provider.dart';
import '../providers/group_provider.dart';
import '../services/bank_integration_service.dart';
import '../models/credit_card_master.dart';
import '../screens/manage_cards_screen.dart';

class BankImportScreen extends StatefulWidget {
  const BankImportScreen({super.key});

  @override
  State<BankImportScreen> createState() => _BankImportScreenState();
}

class _BankImportScreenState extends State<BankImportScreen> {
  String? _selectedBank;
  String? _selectedCardId;
  bool _isImporting = false;
  List<String> _importResults = [];
  int _referenceMonth = DateTime.now().month;
  int _referenceYear = DateTime.now().year;

  final Map<String, BankInfo> _supportedBanks = {
    'nubank': BankInfo(
      name: 'Nubank',
      color: Color(0xFF8A05BE),
      icon: Icons.credit_card,
      hasAPI: false,
      hasCSV: true,
      instructions: 'Exporte o extrato em CSV pelo app ou site do Nubank',
    ),
    'mercadopago': BankInfo(
      name: 'Mercado Pago',
      color: Color(0xFF00B1EA),
      icon: Icons.payment,
      hasAPI: true,
      hasCSV: true,
      instructions: 'Conecte via API ou importe CSV do extrato',
    ),
    'brb': BankInfo(
      name: 'BRB',
      color: Color(0xFF1976D2),
      icon: Icons.account_balance,
      hasAPI: false,
      hasCSV: true,
      instructions: 'Exporte o extrato em CSV pelo internet banking',
    ),
    'itau': BankInfo(
      name: 'Itaú',
      color: Color(0xFFFF6600),
      icon: Icons.account_balance,
      hasAPI: true,
      hasCSV: true,
      instructions: 'Conecte via Open Banking ou importe CSV',
    ),
    'bradesco': BankInfo(
      name: 'Bradesco',
      color: Color(0xFFCC092F),
      icon: Icons.account_balance,
      hasAPI: true,
      hasCSV: true,
      instructions: 'Conecte via Open Banking ou importe CSV',
    ),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCards();
    });
  }

  Future<void> _loadCards() async {
    if (!mounted) return;
    
    // Garantir que o grupo esteja configurado antes de carregar
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final creditCardMasterProvider = Provider.of<CreditCardMasterProvider>(context, listen: false);
    
    if (groupProvider.selectedGroupId != null) {
      creditCardMasterProvider.setCurrentGroup(groupProvider.selectedGroupId!);
    }
    
    await creditCardMasterProvider.loadCards();
  }

  List<CreditCardMaster> _getCardsForBank(String bankName) {
    final provider = Provider.of<CreditCardMasterProvider>(context, listen: false);
    return provider.cards.where((card) => card.bankName == bankName).toList();
  }

  void _onBankSelected(String bankCode) {
    setState(() {
      _selectedBank = bankCode;
      _selectedCardId = null; // Reset card selection when bank changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Importar Dados Bancários',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecione seu banco',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _supportedBanks.length,
              itemBuilder: (context, index) {
                  final bankCode = _supportedBanks.keys.elementAt(index);
                  final bankInfo = _supportedBanks[bankCode]!;
                  
                  return _buildBankCard(bankCode, bankInfo);
                },
              ),
            if (_selectedBank != null) ...[
              const SizedBox(height: 16),
              _buildImportOptions(),
            ],
            if (_importResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImportResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBankCard(String bankCode, BankInfo bankInfo) {
    final isSelected = _selectedBank == bankCode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? bankInfo.color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
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
          onTap: () => _onBankSelected(bankCode),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: bankInfo.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    bankInfo.icon,
                    color: bankInfo.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bankInfo.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (bankInfo.hasAPI)
                            _buildFeatureBadge('API', Colors.green),
                          if (bankInfo.hasAPI && bankInfo.hasCSV)
                            const SizedBox(width: 8),
                          if (bankInfo.hasCSV)
                            _buildFeatureBadge('CSV', Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: bankInfo.color,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildImportOptions() {
    final bankInfo = _supportedBanks[_selectedBank]!;
    
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Opções de Importação',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bankInfo.instructions,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final provider = Provider.of<CreditCardMasterProvider>(context);
              final bankName = _supportedBanks[_selectedBank]?.name ?? '';
              final availableCards = _getCardsForBank(bankName);
              
              // Debug: Log para verificar se os cartões estão sendo carregados
              print('DEBUG: Bank selected: $bankName');
              print('DEBUG: Available cards: ${availableCards.length}');
              print('DEBUG: All cards: ${provider.cards.length}');
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selecionar Cartão',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageCardsScreen(),
                            ),
                          ).then((_) => _loadCards());
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Gerenciar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (availableCards.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.orange.shade600,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nenhum cartão cadastrado para $bankName',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cadastre um cartão antes de importar',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.orange.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedCardId,
                      decoration: InputDecoration(
                        labelText: 'Cartão',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: availableCards.map((card) {
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
                      onChanged: (value) {
                        setState(() {
                          _selectedCardId = value;
                        });
                      },
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Mês/Ano de Referência da Fatura',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _referenceMonth,
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
                      child: Text('$month - ${monthNames[index]}'),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _referenceMonth = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _referenceYear,
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
                    setState(() {
                      _referenceYear = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (bankInfo.hasAPI)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isImporting ? null : () => _connectAPI(),
                    icon: const Icon(Icons.link),
                    label: const Text('Conectar API'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              if (bankInfo.hasAPI && bankInfo.hasCSV)
                const SizedBox(width: 12),
              if (bankInfo.hasCSV)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isImporting ? null : () => _importCSV(),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Importar CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportResults() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Text(
                'Importação Concluída',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._importResults.map((result) => Text(
            result,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.green.shade700,
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _connectAPI() async {
    setState(() => _isImporting = true);
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Funcionalidade de API em desenvolvimento. Use importação CSV.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _importCSV() async {
    // Validar se um cartão foi selecionado
    if (_selectedCardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selecione um cartão antes de importar',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() => _isImporting = true);
      
      try {
        final fileBytes = result.files.single.bytes!;
        
        // Obter o cartão selecionado
        final cardProvider = Provider.of<CreditCardMasterProvider>(context, listen: false);
        final selectedCard = cardProvider.cards.firstWhere((card) => card.id == _selectedCardId);
        
        final transactions = await BankIntegrationService.importFromCSV(
          fileBytes,
          selectedCard,
          'current_user',
          referenceMonth: _referenceMonth,
          referenceYear: _referenceYear,
        );

        final transactionProvider = Provider.of<CreditCardTransactionProvider>(context, listen: false);
        
        await transactionProvider.addTransactions(transactions);

        setState(() {
          _importResults = [
            '${transactions.length} transações importadas com sucesso',
          ];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dados importados com sucesso!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao importar: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isImporting = false);
      }
    }
  }
}

class BankInfo {
  final String name;
  final Color color;
  final IconData icon;
  final bool hasAPI;
  final bool hasCSV;
  final String instructions;

  BankInfo({
    required this.name,
    required this.color,
    required this.icon,
    required this.hasAPI,
    required this.hasCSV,
    required this.instructions,
  });
}
