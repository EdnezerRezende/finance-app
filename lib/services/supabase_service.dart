import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://dinrbvxflxmouisjpmfz.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpbnJidnhmbHhtb3Vpc2pwbWZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg2MTQ3ODIsImV4cCI6MjA2NDE5MDc4Mn0.T7Hhh7Hvo4GpgEycASUCqkQMRcgwFYJv5tHX_Ij39VY';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 10,
      ),
    );
  }

  // Auth methods
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Check if user has a valid session
  static Future<bool> hasValidSession() async {
    try {
      final session = client.auth.currentSession;
      if (session != null) {
        // Refresh the session to ensure it's still valid
        final response = await client.auth.refreshSession();
        return response.session != null;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Initialize persistent session
  static Future<void> initializePersistentSession() async {
    try {
      // Listen to auth state changes and maintain session
      client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        
        if (event == AuthChangeEvent.signedIn && session != null) {
          // Session established, store user info if needed
          _handleSignIn(session);
        } else if (event == AuthChangeEvent.signedOut) {
          // Handle sign out
          _handleSignOut();
        } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
          // Token refreshed, update stored session
          _handleTokenRefresh(session);
        }
      });

      // Try to recover existing session
      await _recoverSession();
    } catch (e) {
      print('Error initializing persistent session: $e');
    }
  }

  static void _handleSignIn(Session session) {
    // Session is automatically persisted by Supabase Flutter
    print('User signed in: ${session.user.email}');
  }

  static void _handleSignOut() {
    print('User signed out');
  }

  static void _handleTokenRefresh(Session session) {
    // Session is automatically updated by Supabase Flutter
    print('Token refreshed for: ${session.user.email}');
  }

  static Future<void> _recoverSession() async {
    try {
      // Supabase Flutter automatically recovers sessions from local storage
      final session = client.auth.currentSession;
      if (session != null) {
        print('Session recovered for: ${session.user.email}');
      }
    } catch (e) {
      print('No existing session to recover: $e');
    }
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Database methods for expenses (transactions)
  static Future<List<Map<String, dynamic>>> getExpenses({DateTime? month}) async {
    if (month != null) {
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);
      
      final response = await client
          .from('expense')
          .select('*')
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date', ascending: false);
      return response;
    } else {
      final response = await client
          .from('expense')
          .select('*')
          .order('date', ascending: false);
      return response;
    }
  }

  // Get expenses by date range
  static Future<List<Map<String, dynamic>>> getExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    final response = await client
        .from('expense')
        .select('*')
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0])
        .order('date', ascending: false);
    return response;
  }

  // Get current month expenses
  static Future<List<Map<String, dynamic>>> getCurrentMonthExpenses() async {
    final now = DateTime.now();
    return getExpenses(month: now);
  }

  static Future<Map<String, dynamic>> insertExpense(Map<String, dynamic> expense) async {
    expense['user_id'] = currentUser!.id;
    final response = await client
        .from('expense')
        .insert(expense)
        .select()
        .single();
    return response;
  }

  static Future<void> updateExpense(int id, Map<String, dynamic> updates) async {
    await client
        .from('expense')
        .update(updates)
        .eq('id', id);
  }

  static Future<void> deleteExpense(int id) async {
    await client
        .from('expense')
        .delete()
        .eq('id', id);
  }

  // Database methods for categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await client
        .from('categories')
        .select()
        .order('categoria');
    return response;
  }

  // Get categories with expense count for a specific month
  static Future<List<Map<String, dynamic>>> getCategoriesWithExpenseCount({DateTime? month}) async {
    var query = client
        .from('categories')
        .select('''
          *,
          expenses!inner(count)
        ''');

    if (month != null) {
      query = query
          .eq('expenses.ano', month.year)
          .eq('expenses.mes', month.month);
    }

    final response = await query.order('name');
    return response;
  }

  static Future<Map<String, dynamic>> insertCategory(Map<String, dynamic> category) async {
    category['user_id'] = currentUser!.id;
    final response = await client
        .from('categories')
        .insert(category)
        .select()
        .single();
    return response;
  }

  // Database methods for finances (general financial data)
  static Future<List<Map<String, dynamic>>> getFinances({DateTime? month}) async {
    var query = client
        .from('finances')
        .select();

    if (month != null) {
      query = query
          .eq('ano', month.year)
          .eq('mes', month.month);
    }

    final response = await query
        .order('ano', ascending: true)
        .order('mes', ascending: true)
        .order('date', ascending: false);
    return response;
  }

  // Get finances by date range
  static Future<List<Map<String, dynamic>>> getFinancesByDateRange(DateTime startDate, DateTime endDate) async {
    final response = await client
        .from('finances')
        .select()
        // .eq('user_id', currentUser!.id)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0])
        .order('date', ascending: false);
    return response;
  }

  // Database methods for finance records (loans/financing)
  static Future<List<Map<String, dynamic>>> getFinanceRecords() async {
    final response = await client
        .from('finances')
        .select()
        .order('created_at', ascending: false);
    return response;
  }

  static Future<Map<String, dynamic>> insertFinance(Map<String, dynamic> finance) async {
    finance['userId'] = currentUser!.id;
    final response = await client
        .from('finances')
        .insert(finance)
        .select()
        .single();
    return response;
  }

  static Future<Map<String, dynamic>> updateFinance(int id, Map<String, dynamic> finance) async {
    final response = await client
        .from('finances')
        .update(finance)
        .eq('id', id)
        .select()
        .single();
    return response;
  }

  static Future<void> deleteFinance(int id) async {
    await client
        .from('finances')
        .delete()
        .eq('id', id);
  }

  // Database methods for user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await client
          .from('usuario')
          .select()
          .eq('user_id', currentUser!.id)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> upsertUserProfile(Map<String, dynamic> profile) async {
    profile['user_id'] = currentUser!.id;
    final response = await client
        .from('usuario')
        .upsert(profile)
        .select()
        .single();
    return response;
  }

  // Purchase methods (compras parceladas)
  static Future<List<Map<String, dynamic>>> getPurchases({DateTime? month}) async {
    var query = client
        .from('purchases')
        .select('''
          *,
          credit_cards!inner(card_name, bank_name)
        ''')
        // .eq('user_id', currentUser!.id)
        ;

    if (month != null) {
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);
      query = query
          .gte('purchase_date', startDate.toIso8601String().split('T')[0])
          .lte('purchase_date', endDate.toIso8601String().split('T')[0]);
    }

    final response = await query.order('purchase_date', ascending: false);
    return response;
  }

  static Future<Map<String, dynamic>> insertPurchase(Map<String, dynamic> purchase) async {
    purchase['user_id'] = currentUser!.id;
    final response = await client
        .from('purchases')
        .insert(purchase)
        .select()
        .single();
    return response;
  }

  static Future<void> updatePurchase(String id, Map<String, dynamic> updates) async {
    await client
        .from('purchases')
        .update(updates)
        .eq('id', id)
        .eq('user_id', currentUser!.id);
  }

  static Future<void> deletePurchase(String id) async {
    await client
        .from('purchases')
        .update({'status': 'cancelled'})
        .eq('id', id)
        // .eq('user_id', currentUser!.id)
        ;
  }

  // Installment methods (parcelas) - Nova estrutura da tabela cartao
  static Future<List<Map<String, dynamic>>> getInstallments({DateTime? month}) async {
    if (!isLoggedIn) throw Exception('User not authenticated');

    var query = client
        .from('cartao')
        .select('*');

    if (month != null) {
      query = query
          .eq('mes', month.month)
          .eq('ano', month.year);
    }

    final response = await query.order('mes', ascending: true).order('ano', ascending: true);
    return response;
  }

  static Future<List<Map<String, dynamic>>> getUpcomingInstallments(int days) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));
    final response = await client
        .from('cartao')
        .select('*')
        .eq('status', 'pending')
        .gte('ano', now.year)
        .lte('ano', endDate.year)
        .order('ano', ascending: true)
        .order('mes', ascending: true);
    return response;
  }

  static Future<Map<String, dynamic>> addInstallment(Map<String, dynamic> installment) async {
    final response = await client
        .from('cartao')
        .insert(installment)
        .select()
        .single();
    return response;
  }

  static Future<void> deleteInstallment(String id) async {
    await client.from('cartao').delete().eq('id', id);
  }

  static Future<void> updateInstallment(String id, Map<String, dynamic> data) async {
    await client.from('cartao').update(data).eq('id', id);
  }

  static Future<void> updateCreditCard(String id, Map<String, dynamic> data) async {
    await client.from('credit_cards').update(data).eq('id', id);
  }

  static Future<void> deleteCreditCard(String id) async {
    await client.from('credit_cards').delete().eq('id', id);
  }

  static Future<void> payInstallment(String id, double amount, String paymentMethod, {String? notes}) async {
    await client
        .from('cartao')
        .update({
          'status': 'paid',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  // Credit card methods (simplified for basic card info)
  static Future<List<Map<String, dynamic>>> getCreditCards() async {
    final response = await client
        .from('credit_cards')
        .select()
        // .eq('user_id', currentUser!.id)
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return response;
  }

  static Future<Map<String, dynamic>> insertCreditCard(Map<String, dynamic> card) async {
    card['user_id'] = currentUser!.id;
    final response = await client
        .from('credit_cards')
        .insert(card)
        .select()
        .single();
    return response;
  }
}
