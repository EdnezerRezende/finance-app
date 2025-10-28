import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/credit_card_master_provider.dart';
import '../providers/group_provider.dart';
import '../models/credit_card_master.dart';

class ManageCardsScreen extends StatefulWidget {
  const ManageCardsScreen({super.key});

  @override
  State<ManageCardsScreen> createState() => _ManageCardsScreenState();
}

class _ManageCardsScreenState extends State<ManageCardsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastFourDigitsController = TextEditingController();
  String _selectedBank = 'nubank';
  
  final Map<String, Map<String, dynamic>> _bankOptions = {
    'nubank': {
      'name': 'Nubank',
      'color': '#8A05BE',
      'closingDay': 15,
      'dueDay': 10,
    },
    'mercadopago': {
      'name': 'Mercado Pago',
      'color': '#00B1EA',
      'closingDay': 1,
      'dueDay': 15,
    },
    'brb': {
      'name': 'BRB',
      'color': '#FF6B35',
      'closingDay': 5,
      'dueDay': 25,
    },
    'itau': {
      'name': 'Itaú',
      'color': '#FF8C00',
      'closingDay': 10,
      'dueDay': 5,
    },
    'bradesco': {
      'name': 'Bradesco',
      'color': '#CC092F',
      'closingDay': 8,
      'dueDay': 3,
    },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gerenciar Cartões',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CreditCardMasterProvider>(
        builder: (context, provider, child) {
          // Usar agrupamento do provider
          final cardsByBank = provider.cardsByBank;

          return Column(
            children: [
              // Lista de cartões cadastrados
              Expanded(
                child: cardsByBank.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.credit_card_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum cartão cadastrado',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Adicione um cartão para começar',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cardsByBank.length,
                        itemBuilder: (context, index) {
                          final bankName = cardsByBank.keys.elementAt(index);
                          final cards = cardsByBank[bankName]!;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ExpansionTile(
                              title: Text(
                                bankName,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${cards.length} cartão(ões)',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              children: cards.map((card) {
                                return ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 25,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(card.cardColor.replaceAll('#', '0xFF'))),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.credit_card,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  title: Text(
                                    card.name,
                                    style: GoogleFonts.poppins(fontSize: 16),
                                  ),
                                  subtitle: Text(
                                    card.cardNumberMasked,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteCard(card),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "manage_cards_fab",
        onPressed: _showAddCardDialog,
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddCardDialog() {
    _nameController.clear();
    _lastFourDigitsController.clear();
    _selectedBank = 'nubank';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Adicionar Cartão',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedBank,
                  decoration: const InputDecoration(
                    labelText: 'Operadora',
                    border: OutlineInputBorder(),
                  ),
                  items: _bankOptions.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Color(int.parse(entry.value['color'].replaceAll('#', '0xFF'))),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(entry.value['name']),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedBank = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Cartão',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: Cartão Principal, Cartão Empresarial',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastFourDigitsController,
                  decoration: const InputDecoration(
                    labelText: '4 Últimos Dígitos',
                    border: OutlineInputBorder(),
                    hintText: '1234',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '4 últimos dígitos são obrigatórios';
                    }
                    if (value.length != 4) {
                      return 'Digite exatamente 4 dígitos';
                    }
                    return null;
                  },
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
              onPressed: () => _addCard(),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCard() async {
    if (!_formKey.currentState!.validate()) return;

    final bankInfo = _bankOptions[_selectedBank]!;
    final lastFourDigits = _lastFourDigitsController.text.trim();
    
    final card = CreditCardMaster(
      id: '',
      name: _nameController.text.trim(),
      cardNumberMasked: '**** **** **** $lastFourDigits',
      bankName: bankInfo['name'],
      cardType: 'credit',
      creditLimit: 0.0,
      closingDay: bankInfo['closingDay'],
      dueDay: bankInfo['dueDay'],
      cardColor: bankInfo['color'],
    );

    try {
      final provider = Provider.of<CreditCardMasterProvider>(context, listen: false);
      await provider.addCard(card);
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cartão adicionado com sucesso!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao adicionar cartão: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCard(CreditCardMaster card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar Exclusão',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Deseja realmente excluir o cartão "${card.name}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final provider = Provider.of<CreditCardMasterProvider>(context, listen: false);
        await provider.deleteCard(card.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cartão excluído com sucesso!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao excluir cartão: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastFourDigitsController.dispose();
    super.dispose();
  }
}
