import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' hide Key;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  static const String _keyPrefix = 'user_encryption_key_';
  static const String _saltPrefix = 'user_salt_';
  static const int _keyLength = 32; // 256 bits
  static const int _saltLength = 16; // 128 bits
  static const int _iterations = 10000; // PBKDF2 iterations

  /// Gera uma chave de criptografia única para o usuário com salt fixo para consistência
  static Future<String> _generateUserKey(String userId, String userPassword) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Usar salt determinístico baseado no userId para garantir consistência entre plataformas
    final saltString = 'salt_$userId';
    final hmacForSalt = Hmac(sha256, utf8.encode('deterministic_salt_key'));
    final saltDigest = hmacForSalt.convert(utf8.encode(saltString));
    final salt = saltDigest.bytes.take(_saltLength).toList();
    
    debugPrint('🔑 Gerando chave com salt determinístico para usuário: $userId');
    debugPrint('🔑 Salt (primeiros 8 bytes): ${salt.take(8).toList()}');
    
    // Derivar chave usando PBKDF2
    final key = _deriveKey(userPassword, salt, _iterations, _keyLength);
    final keyBase64 = base64Encode(key);
    
    debugPrint('🔑 Chave gerada (primeiros 8 bytes): ${key.take(8).toList()}');
    
    // Armazenar chave criptografada localmente (opcional para performance)
    await prefs.setString('$_keyPrefix$userId', keyBase64);
    await prefs.setString('$_saltPrefix$userId', base64Encode(salt));
    
    return keyBase64;
  }

  /// Obtém a chave de criptografia do usuário com validação iOS
  static Future<String?> getUserKey(String userId, String userPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Tentar obter chave existente
      String? existingKey = prefs.getString('$_keyPrefix$userId');
      
      if (existingKey != null) {
        // Validar se a chave é válida (base64 de 32 bytes)
        try {
          final keyBytes = base64Decode(existingKey);
          if (keyBytes.length == _keyLength) {
            debugPrint('✅ Chave existente válida encontrada para usuário: $userId');
            return existingKey;
          } else {
            debugPrint('❌ Chave existente inválida (tamanho: ${keyBytes.length}), regenerando...');
          }
        } catch (e) {
          debugPrint('❌ Erro ao decodificar chave existente: $e, regenerando...');
        }
      }
      
      // Gerar nova chave se não existir ou for inválida
      debugPrint('🔑 Gerando nova chave para usuário: $userId');
      return await _generateUserKey(userId, userPassword);
    } catch (e) {
      debugPrint('❌ Erro crítico ao obter chave do usuário: $e');
      return null;
    }
  }

  /// Criptografa um campo de texto
  static String encryptField(String data, String keyBase64) {
    if (data.isEmpty) return data;
    
    try {
      final key = encrypt.Key(base64Decode(keyBase64));
      final iv = IV.fromSecureRandom(16); // 128 bits IV
      final encrypter = Encrypter(AES(key));
      
      final encrypted = encrypter.encrypt(data, iv: iv);
      
      // Combinar IV + dados criptografados em formato: iv:encrypted
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Erro ao criptografar dados: $e');
    }
  }

  /// Descriptografa um campo de texto com fallback para dados corrompidos
  static String decryptField(String encryptedData, String keyBase64) {
    if (encryptedData.isEmpty) return encryptedData;
    
    try {
      // Verificar se está no formato iv:encrypted
      if (!encryptedData.contains(':')) {
        debugPrint('📝 Dados não criptografados detectados (migração): ${encryptedData.length} chars');
        return encryptedData;
      }
      
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        debugPrint('❌ Formato inválido de dados criptografados: ${parts.length} partes');
        return encryptedData;
      }
      
      debugPrint('🔓 Tentando descriptografar: IV=${parts[0].length} chars, Data=${parts[1].length} chars');
      
      final key = encrypt.Key(base64Decode(keyBase64));
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      
      final encrypter = Encrypter(AES(key));
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      
      debugPrint('✅ Descriptografia bem-sucedida: ${decrypted.length} chars');
      return decrypted;
    } catch (e) {
      // Tratar dados criptografados corrompidos como texto de fallback
      if (e.toString().contains('pad block') || e.toString().contains('Invalid argument')) {
        debugPrint('🔄 Dados criptografados corrompidos detectados - usando fallback');
        return '[Dados corrompidos - recriar transação]';
      }
      
      debugPrint('❌ Erro na descriptografia: $e');
      debugPrint('❌ Dados problemáticos: ${encryptedData.substring(0, math.min(50, encryptedData.length))}...');
      // Se falhar na descriptografia, retornar dados originais (migração)
      return encryptedData;
    }
  }

  /// Criptografa valores numéricos
  static String encryptNumericField(double value, String keyBase64) {
    return encryptField(value.toString(), keyBase64);
  }

  /// Descriptografa valores numéricos com fallback para dados corrompidos
  static double decryptNumericField(String encryptedValue, String keyBase64) {
    try {
      final decrypted = decryptField(encryptedValue, keyBase64);
      
      // Se retornou texto de fallback para dados corrompidos, retornar 0.0
      if (decrypted == '[Dados corrompidos - recriar transação]') {
        return 0.0;
      }
      
      return double.tryParse(decrypted) ?? 0.0;
    } catch (e) {
      // Se falhar, tentar converter diretamente (dados não criptografados)
      return double.tryParse(encryptedValue) ?? 0.0;
    }
  }

  /// Verifica se um campo está criptografado
  static bool isEncrypted(String data) {
    if (data.isEmpty) return false;
    
    // Verificar se está no formato iv:encrypted
    return data.contains(':') && data.split(':').length == 2;
  }

  /// Gera bytes aleatórios seguros com melhor compatibilidade iOS/Android
  static List<int> _generateRandomBytes(int length) {
    try {
      // Usar IV.fromSecureRandom que é mais confiável entre plataformas
      final iv = IV.fromSecureRandom(length);
      return iv.bytes;
    } catch (e) {
      debugPrint('Erro ao gerar bytes seguros, usando fallback: $e');
      // Fallback para Random.secure()
      final random = math.Random.secure();
      return List<int>.generate(length, (i) => random.nextInt(256));
    }
  }

  /// Deriva uma chave usando PBKDF2 melhorado para compatibilidade iOS/Android
  static List<int> _deriveKey(String password, List<int> salt, int iterations, int keyLength) {
    final passwordBytes = utf8.encode(password);
    
    // Implementação PBKDF2 mais robusta e compatível entre plataformas
    var derivedKey = <int>[];
    var blockIndex = 1;
    
    while (derivedKey.length < keyLength) {
      // Criar bloco inicial: salt + block_index (big-endian)
      var block = List<int>.from(salt);
      block.addAll([
        (blockIndex >> 24) & 0xff,
        (blockIndex >> 16) & 0xff,
        (blockIndex >> 8) & 0xff,
        blockIndex & 0xff,
      ]);
      
      // Primeira iteração
      var hmac = Hmac(sha256, passwordBytes);
      var u = hmac.convert(block).bytes;
      var result = List<int>.from(u);
      
      // Iterações restantes
      for (int i = 1; i < iterations; i++) {
        hmac = Hmac(sha256, passwordBytes);
        u = hmac.convert(u).bytes;
        
        // XOR com resultado anterior
        for (int j = 0; j < result.length; j++) {
          result[j] ^= u[j];
        }
      }
      
      derivedKey.addAll(result);
      blockIndex++;
    }
    
    return derivedKey.take(keyLength).toList();
  }

  /// Limpa as chaves armazenadas localmente (logout)
  static Future<void> clearUserKeys(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$userId');
    await prefs.remove('$_saltPrefix$userId');
    debugPrint('🗑️ Chaves removidas para usuário: $userId');
  }
  
  /// Força regeneração de chaves (para resolver inconsistências)
  static Future<void> forceKeyRegeneration(String userId) async {
    debugPrint('🔄 Forçando regeneração de chaves para usuário: $userId');
    await clearUserKeys(userId);
  }

  /// Inicializa a criptografia para um usuário
  static Future<String> initializeEncryption(String userId, String userPassword) async {
    return await _generateUserKey(userId, userPassword);
  }

  /// Gera uma senha temporária baseada no email do usuário (para demonstração)
  static String generateTempPassword(String userEmail) {
    // Em produção, isso deveria ser uma senha real do usuário
    // Por enquanto, usamos uma derivação do email
    final hmac = Hmac(sha256, utf8.encode('temp_key_salt'));
    final digest = hmac.convert(utf8.encode(userEmail));
    return base64Encode(digest.bytes).substring(0, 16);
  }
}
