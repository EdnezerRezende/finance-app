class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  
  // Validação para garantir que as variáveis foram definidas
  static void validateEnvironment() {
    if (supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL environment variable not set');
    }
    
    if (supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY environment variable not set');
    }
  }
}
