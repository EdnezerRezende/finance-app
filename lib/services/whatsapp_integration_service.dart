import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class WhatsAppIntegrationService {
  static final _supabase = Supabase.instance.client;

  static String generateVerificationCode() {
    return (Random().nextInt(900000) + 100000).toString();
  }

  static Future<String?> createIntegration(String groupId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final code = generateVerificationCode();

    final existing = await _supabase
        .from('whatsapp_integrations')
        .select()
        .eq('user_id', userId)
        .eq('group_id', groupId)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('whatsapp_integrations')
          .update({
            'verification_code': code,
            'is_verified': false,
            'is_active': true,
          })
          .eq('id', existing['id']);
    } else {
      await _supabase.from('whatsapp_integrations').insert({
        'group_id': groupId,
        'user_id': userId,
        'verification_code': code,
        'is_verified': false,
        'is_active': true,
      });
    }

    return code;
  }

  static Future<Map<String, dynamic>?> getIntegrationStatus(String groupId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    return await _supabase
        .from('whatsapp_integrations')
        .select()
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();
  }

  static Future<bool> removeIntegration(String integrationId) async {
    await _supabase
        .from('whatsapp_integrations')
        .delete()
        .eq('id', integrationId);
    return true;
  }
}
