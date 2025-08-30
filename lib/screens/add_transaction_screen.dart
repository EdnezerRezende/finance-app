import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/supabase_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  TransactionType _selectedType = TransactionType.DESPESA;
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  List<Category> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await SupabaseService.getCategories();
      setState(() {
        _categories = data.map((json) => Category.fromSupabase(json)).toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar categorias: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Adicionar Transação',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Tipo de transação
              Container(
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
                  children: [
                    Expanded(
                      child: RadioListTile<TransactionType>(
                        title: Text('Receita', style: GoogleFonts.poppins()),
                        value: TransactionType.ENTRADA,
                        groupValue: _selectedType,
                        onChanged: (value) => setState(() => _selectedType = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<TransactionType>(
                        title: Text('Despesa', style: GoogleFonts.poppins()),
                        value: TransactionType.DESPESA,
                        groupValue: _selectedType,
                        onChanged: (value) => setState(() => _selectedType = value!),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Descrição
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Valor
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  labelStyle: GoogleFonts.poppins(),
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um valor';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor, insira um valor válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Categoria
              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade300,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category.name,
                                style: GoogleFonts.poppins(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (Category? value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor, selecione uma categoria';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 16),
              
              // Data
              ListTile(
                title: Text('Data', style: GoogleFonts.poppins()),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2050),
                    currentDate: _selectedDate,
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              const Spacer(),
              
              // Botão salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Salvar Transação',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final transaction = Transaction(
        id: 0, // Will be auto-generated by database
        type: _selectedType == TransactionType.DESPESA ? 'DESPESA' : 'ENTRADA',
        amount: double.parse(_amountController.text),
        description: _descriptionController.text,
        category: _selectedCategory!.name,
        date: _selectedDate,
        userId: 'current_user', // Should be replaced with actual user ID
      );

      Provider.of<TransactionProvider>(context, listen: false)
          .addTransaction(transaction);

      Navigator.pop(context);
    }
  }
}
