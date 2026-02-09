import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/credit_card.dart';

class CreditCardDetailsScreen extends StatelessWidget {
  final String bankName;
  final List<CreditCard> cards;
  final double totalBalance;
  final String cardColor;

  const CreditCardDetailsScreen({
    super.key,
    required this.bankName,
    required this.cards,
    required this.totalBalance,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // Agrupar por mês/ano
    final groupedByMonth = <String, List<CreditCard>>{};
    for (final card in cards) {
      final monthKey = '${card.mes.toString().padLeft(2, '0')}/${card.ano}';
      if (!groupedByMonth.containsKey(monthKey)) {
        groupedByMonth[monthKey] = [];
      }
      groupedByMonth[monthKey]!.add(card);
    }

    // Ordenar por mês/ano (mais recente primeiro)
    final sortedKeys = groupedByMonth.keys.toList()
      ..sort((a, b) {
        final partsA = a.split('/');
        final partsB = b.split('/');
        final dateA = DateTime(int.parse(partsA[1]), int.parse(partsA[0]));
        final dateB = DateTime(int.parse(partsB[1]), int.parse(partsB[0]));
        return dateB.compareTo(dateA);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          bankName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header com resumo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(int.parse(cardColor.replaceAll('#', '0xFF'))),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Total Gasto',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(totalBalance),
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${cards.length} transações',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de transações agrupadas por mês
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final monthKey = sortedKeys[index];
                final monthCards = groupedByMonth[monthKey]!;
                final monthTotal = monthCards.fold<double>(0, (sum, card) => sum + card.currentBalance);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      monthKey,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    subtitle: Text(
                      '${currencyFormat.format(monthTotal)} • ${monthCards.length} transações',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    iconColor: Colors.grey.shade600,
                    collapsedIconColor: Colors.grey.shade600,
                    children: monthCards.map((card) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: Text(
                          card.name.replaceFirst('${card.bankName} - ', ''),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        subtitle: Text(
                          dateFormat.format(card.createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Text(
                          currencyFormat.format(card.currentBalance),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: card.currentBalance >= 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
