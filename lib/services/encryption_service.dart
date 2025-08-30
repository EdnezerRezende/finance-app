import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static const String _keyPrefix = 'user_encryption_key_';
  static const String _saltPrefix = 'user_salt_';
  static const int _keyLength = 32; // 256 bits
  static const int _saltLength = 16; // 128 bits
  static const int _iterations = 10000; // PBKDF2 iterations

  /// Gera uma chave de criptografia única para o usuário
  static Future<String> _generateUserKey(String userId, String userPassword) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Verificar se já existe um salt para este usuário
    String? existingSalt = prefs.getString('$_saltPrefix$userId');
    
    List<int> salt;
    if (existingSalt != null) {
      salt = base64Decode(existingSalt);
    } else {
      // Gerar novo salt
      salt = _generateRandomBytes(_saltLength);
      await prefs.setString('$_saltPrefix$userId', base64Encode(salt));
    }
    
    // Derivar chave usando PBKDF2
    final key = _deriveKey(userPassword, salt, _iterations, _keyLength);
    final keyBase64 = base64Encode(key);
    
    // Armazenar chave criptografada localmente (opcional para performance)
    await prefs.setString('$_keyPrefix$userId', keyBase64);
    
    return keyBase64;
  }

  /// Obtém a chave de criptografia do usuário
  static Future<String?> getUserKey(String userId, String userPassword) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Tentar obter chave existente
    String? existingKey = prefs.getString('$_keyPrefix$userId');
    
    if (existingKey != null) {
      return existingKey;
    }
    
    // Gerar nova chave se não existir
    return await _generateUserKey(userId, userPassword);
  }

  /// Criptografa um campo de texto
  static String encryptField(String data, String keyBase64) {
    if (data.isEmpty) return data;
    
    try {
      final key = Key(base64Decode(keyBase64));
      final iv = IV.fromSecureRandom(16); // 128 bits IV
      final encrypter = Encrypter(AES(key));
      
      final encrypted = encrypter.encrypt(data, iv: iv);
      
      // Combinar IV + dados criptografados em formato: iv:encrypted
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Erro ao criptografar dados: $e');
    }
  }

  /// Descriptografa um campo de texto
  static String decryptField(String encryptedData, String keyBase64) {
    if (encryptedData.isEmpty) return encryptedData;
    
    try {
      // Verificar se está no formato iv:encrypted
      if (!encryptedData.contains(':')) {
        // Dados não criptografados (migração)
        return encryptedData;
      }
      
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        return encryptedData;
      }
      
      final key = Key(base64Decode(keyBase64));
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      
      final encrypter = Encrypter(AES(key));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      // Se falhar na descriptografia, retornar dados originais (migração)
      return encryptedData;
    }
  }

  /// Criptografa valores numéricos
  static String encryptNumericField(double value, String keyBase64) {
    return encryptField(value.toString(), keyBase64);
  }

  /// Descriptografa valores numéricos
  static double decryptNumericField(String encryptedValue, String keyBase64) {
    try {
      final decrypted = decryptField(encryptedValue, keyBase64);
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

  /// Gera bytes aleatórios seguros
  static List<int> _generateRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (i) => random.nextInt(256));
  }

  /// Deriva uma chave usando PBKDF2 simplificado
  static List<int> _deriveKey(String password, List<int> salt, int iterations, int keyLength) {
    final passwordBytes = utf8.encode(password);
    
    // Implementação simplificada do PBKDF2
    var result = <int>[];
    var currentHash = passwordBytes + salt;
    
    for (int i = 0; i < iterations; i++) {
      final hmac = Hmac(sha256, passwordBytes);
      final digest = hmac.convert(currentHash);
      currentHash = digest.bytes;
    }
    
    // Expandir para o tamanho da chave necessário
    while (result.length < keyLength) {
      final hmac = Hmac(sha256, passwordBytes);
      final digest = hmac.convert(currentHash + [result.length]);
      result.addAll(digest.bytes);
    }
    
    return result.take(keyLength).toList();
  }

  /// Limpa as chaves armazenadas localmente (logout)
  static Future<void> clearUserKeys(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$userId');
    await prefs.remove('$_saltPrefix$userId');
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
