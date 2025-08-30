import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class SupabaseService {

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    // Validar variáveis de ambiente antes de inicializar
    EnvConfig.validateEnvironment();
    
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
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
  static Future<List<Map<String, dynamic>>> getExpenses({DateTime? month, String? groupId}) async {
    var query = client.from('expense').select('*');
    
    if (groupId != null) {
      query = query.eq('group_id', groupId);
    }
    
    if (month != null) {
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);
      query = query
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());
    }
    
    final response = await query.order('date', ascending: false);
    return response;
  }

  // Get expenses by date range
  static Future<List<Map<String, dynamic>>> getExpensesByDateRange(DateTime startDate, DateTime endDate, {String? groupId}) async {
    var query = client
        .from('expense')
        .select('*')
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);
    
    if (groupId != null) {
      query = query.eq('group_id', groupId);
    }
    
    final response = await query.order('date', ascending: false);
    return response;
  }

  // Get current month expenses
  static Future<List<Map<String, dynamic>>> getCurrentMonthExpenses() async {
    final now = DateTime.now();
    return getExpenses(month: now);
  }

  static Future<Map<String, dynamic>> insertExpense(Map<String, dynamic> expense) async {
    expense['userId'] = currentUser!.id;
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
  static Future<List<Map<String, dynamic>>> getFinanceRecords({String? groupId}) async {
    var query = client.from('finances').select();
    
    if (groupId != null) {
      query = query.eq('group_id', groupId);
    }
    
    final response = await query.order('created_at', ascending: false);
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
  static Future<List<Map<String, dynamic>>> getInstallments({DateTime? month, required String groupId}) async {
    if (!isLoggedIn) throw Exception('User not authenticated');

    var query = client
        .from('cartao')
        .select('*')
        .eq('group_id', groupId);

    if (month != null) {
      query = query
          .eq('mes', month.month)
          .eq('ano', month.year);
    }

    final response = await query.order('mes', ascending: true).order('ano', ascending: true);
    return response;
  }

  static Future<List<Map<String, dynamic>>> getUpcomingInstallments(int days, {required String groupId}) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));
    var query = client
        .from('cartao')
        .select('*')
        .eq('group_id', groupId)
        .eq('status', 'pending')
        .gte('ano', now.year)
        .lte('ano', endDate.year);
    
    if (groupId != null) {
      query = query.eq('group_id', groupId);
    }
    
    final response = await query
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
  static Future<List<Map<String, dynamic>>> getCreditCards({required String groupId, DateTime? month}) async {
    var query = client
        .from('cartao')
        .select()
        .eq('group_id', groupId);
    
    if (month != null) {
      query = query
          .eq('mes', month.month)
          .eq('ano', month.year);
    }
    
    final response = await query.order('mes', ascending: true).order('ano', ascending: true);
    return response;
  }

  static Future<Map<String, dynamic>> insertCreditCard(Map<String, dynamic> card) async {
    card['userId'] = currentUser!.id;
    final response = await client
        .from('cartao')
        .insert(card)
        .select()
        .single();
    return response;
  }

  // Group management methods
  static Future<List<Map<String, dynamic>>> getUserGroups() async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    
    final response = await client
        .from('group_members')
        .select('''
          *,
          groups!inner(*)
        ''')
        .eq('user_id', currentUser!.id)
        .eq('status', 'active')
        .order('joined_at', ascending: false);
    
    // Para cada grupo, buscar a contagem de membros usando query direta
    for (var item in response) {
      final groupId = item['group_id'];
      final memberCountResponse = await client
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('status', 'active');
      
      item['member_count'] = (memberCountResponse as List).length;
    }
    
    return response;
  }

  static Future<Map<String, dynamic>> createGroup(String name, String description) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    
    final groupData = {
      'name': name,
      'description': description,
      'owner_id': currentUser!.id,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    final response = await client
        .from('groups')
        .insert(groupData)
        .select()
        .single();
    
    // Add creator as group owner
    await client
        .from('group_members')
        .insert({
          'group_id': response['id'],
          'user_id': currentUser!.id,
          'user_email': currentUser!.email!,
          'role': 'owner',
          'status': 'active',
          'joined_at': DateTime.now().toIso8601String(),
        });
    
    return response;
  }

  static Future<void> deleteGroup(String groupId) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    
    await client
        .from('groups')
        .delete()
        .eq('id', groupId)
        .eq('owner_id', currentUser!.id);
  }

  static Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    
    final response = await client
        .from('group_members')
        .select('id, group_id, user_id, role, joined_at, invited_by, status, user_email')
        .eq('group_id', groupId)
        .order('joined_at', ascending: true);
    return response;
  }

  static Future<void> inviteUserToGroup(String groupId, String userEmail) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    
    // Check if user is already a member
    final existingMember = await client
        .from('group_members')
        .select('id')
        .eq('group_id', groupId)
        .eq('user_email', userEmail)
        .maybeSingle();
    
    if (existingMember != null) {
      throw Exception('User is already a member of this group');
    }
    
    await client
        .from('group_members')
        .insert({
          'group_id': groupId,
          'user_email': userEmail,
          'role': 'member',
          'status': 'pending',
          'invited_by': currentUser!.id,
          'invited_at': DateTime.now().toIso8601String(),
        });
  }

  static Future<List<Map<String, dynamic>>> getPendingInvites() async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    
    final response = await client
        .from('group_members')
        .select('''
          *,
          groups!inner(name),
          inviter:invited_by(email)
        ''')
        .eq('user_email', currentUser!.email!)
        .eq('status', 'pending')
        .order('invited_at', ascending: false);
    return response;
  }

  static Future<void> respondToGroupInvite(String inviteId, bool accept) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    
    if (accept) {
      await client
          .from('group_members')
          .update({
            'status': 'active',
            'user_id': currentUser!.id,
            'joined_at': DateTime.now().toIso8601String(),
          })
          .eq('id', inviteId)
          .eq('user_email', currentUser!.email!);
    } else {
      await client
          .from('group_members')
          .delete()
          .eq('id', inviteId)
          .eq('user_email', currentUser!.email!);
    }
  }

  static Future<void> removeGroupMember(String groupId, String memberId) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    
    await client
        .from('group_members')
        .delete()
        .eq('id', memberId)
        .eq('group_id', groupId);
  }

  static Future<void> updateMemberRole(String memberId, String newRole) async {
    if (!isLoggedIn) throw Exception('User not authenticated');
    
    await client
        .from('group_members')
        .update({'role': newRole})
        .eq('id', memberId);
  }
}
