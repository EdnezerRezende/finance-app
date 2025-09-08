void main() {
  // Teste: Dezembro 2024 + 5 meses
  final baseDate = DateTime(2024, 12, 15);
  print('Data base: ${baseDate.day}/${baseDate.month}/${baseDate.year}');
  
  for (int i = 0; i < 5; i++) {
    final targetDate = DateTime(
      baseDate.year,
      baseDate.month + i,
      baseDate.day,
    );
    print('Mês ${i + 1}: ${targetDate.day}/${targetDate.month}/${targetDate.year}');
  }
  
  print('\n--- Teste com lógica corrigida ---');
  
  for (int i = 0; i < 5; i++) {
    final targetDate = DateTime(
      baseDate.year,
      baseDate.month + i,
      baseDate.day,
    );
    print('Mês ${i + 1}: ${targetDate.day}/${targetDate.month}/${targetDate.year}');
  }
}
