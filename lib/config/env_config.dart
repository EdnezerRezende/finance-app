class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dinrbvxflxmouisjpmfz.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpbnJidnhmbHhtb3Vpc2pwbWZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg2MTQ3ODIsImV4cCI6MjA2NDE5MDc4Mn0.T7Hhh7Hvo4GpgEycASUCqkQMRcgwFYJv5tHX_Ij39VY',
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
