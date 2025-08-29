class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here',
  );
  
  // Validação para garantir que as variáveis foram definidas
  static void validateEnvironment() {
    if (supabaseUrl == 'https://your-project.supabase.co') {
      throw Exception('SUPABASE_URL environment variable not set');
    }
    
    if (supabaseAnonKey == 'your-anon-key-here') {
      throw Exception('SUPABASE_ANON_KEY environment variable not set');
    }
  }
}
