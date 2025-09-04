import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/encryption_service.dart';

class EncryptionProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  String? _userEncryptionKey;
  bool _isEncryptionEnabled = false;
  bool _isInitialized = false;
  String? _error;

  // Getters
  bool get isEncryptionEnabled => _isEncryptionEnabled;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get userEncryptionKey => _userEncryptionKey;

  /// Inicializa a criptografia para o usuário atual com regeneração forçada
  Future<void> initializeEncryption({bool forceRegenerate = false}) async {
    try {
      _error = null;
      debugPrint('🔐 Iniciando inicialização da criptografia...');
      
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      debugPrint('🔐 Usuário autenticado: ${user.email}');
      
      // Forçar regeneração se solicitado
      if (forceRegenerate) {
        debugPrint('🔄 Forçando regeneração de chaves...');
        await EncryptionService.forceKeyRegeneration(user.id);
      }
      
      // Por enquanto, usar uma senha temporária baseada no email
      // Em produção, isso seria a senha real do usuário
      final tempPassword = EncryptionService.generateTempPassword(user.email!);
      debugPrint('🔐 Senha temporária gerada: ${tempPassword.length} chars');
      
      // Gerar/obter chave de criptografia
      _userEncryptionKey = await EncryptionService.getUserKey(user.id, tempPassword);
      
      if (_userEncryptionKey != null) {
        // Validar a chave antes de habilitar
        try {
          final testData = 'test_validation';
          final encrypted = EncryptionService.encryptField(testData, _userEncryptionKey!);
          final decrypted = EncryptionService.decryptField(encrypted, _userEncryptionKey!);
          
          if (decrypted == testData) {
            _isEncryptionEnabled = true;
            _isInitialized = true;
            debugPrint('✅ Criptografia inicializada e validada com sucesso!');
          } else {
            throw Exception('Falha na validação da criptografia: dados não coincidem');
          }
        } catch (validationError) {
          debugPrint('❌ Erro na validação da criptografia: $validationError');
          // Limpar chave inválida e tentar regenerar
          await EncryptionService.clearUserKeys(user.id);
          _userEncryptionKey = await EncryptionService.getUserKey(user.id, tempPassword);
          
          if (_userEncryptionKey != null) {
            _isEncryptionEnabled = true;
            _isInitialized = true;
            debugPrint('✅ Criptografia regenerada com sucesso!');
          } else {
            throw Exception('Falha ao regenerar chave de criptografia');
          }
        }
      } else {
        throw Exception('Falha ao obter chave de criptografia');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erro na inicialização da criptografia: $e');
      _error = e.toString();
      _isEncryptionEnabled = false;
      _isInitialized = false;
      notifyListeners();
    }
  }
  
  /// Força regeneração de chaves para resolver inconsistências
  Future<void> regenerateKeys() async {
    await initializeEncryption(forceRegenerate: true);
  }

  /// Criptografa um campo de texto
  String encryptField(String data) {
    if (!_isEncryptionEnabled || _userEncryptionKey == null || data.isEmpty) {
      return data;
    }
    
    try {
      return EncryptionService.encryptField(data, _userEncryptionKey!);
    } catch (e) {
      debugPrint('Erro ao criptografar campo: $e');
      return data; // Retorna dados originais em caso de erro
    }
  }

  /// Descriptografa um campo de texto com melhor tratamento de erro iOS
  String decryptField(String encryptedData) {
    if (!_isEncryptionEnabled || _userEncryptionKey == null || encryptedData.isEmpty) {
      return encryptedData;
    }
    
    try {
      final result = EncryptionService.decryptField(encryptedData, _userEncryptionKey!);
      return result;
    } catch (e) {
      debugPrint('❌ Erro ao descriptografar campo: $e');
      debugPrint('❌ Dados problemáticos: ${encryptedData.substring(0, math.min(20, encryptedData.length))}...');
      
      // Se for um erro crítico de chave, marcar para reinicialização
      if (e.toString().contains('Invalid key') || e.toString().contains('key')) {
        debugPrint('🔄 Erro de chave detectado, marcando para reinicialização...');
        _error = 'Erro de chave de criptografia - reinicialização necessária';
        _isEncryptionEnabled = false;
        notifyListeners();
      }
      
      return encryptedData; // Retorna dados originais em caso de erro
    }
  }

  /// Criptografa um valor numérico
  String encryptNumericField(double value) {
    if (!_isEncryptionEnabled || _userEncryptionKey == null) {
      return value.toString();
    }
    
    try {
      return EncryptionService.encryptNumericField(value, _userEncryptionKey!);
    } catch (e) {
      debugPrint('Erro ao criptografar valor numérico: $e');
      return value.toString();
    }
  }

  /// Descriptografa um valor numérico com melhor tratamento de erro iOS
  double decryptNumericField(String encryptedValue) {
    if (!_isEncryptionEnabled || _userEncryptionKey == null) {
      return double.tryParse(encryptedValue) ?? 0.0;
    }
    
    try {
      final result = EncryptionService.decryptNumericField(encryptedValue, _userEncryptionKey!);
      return result;
    } catch (e) {
      debugPrint('❌ Erro ao descriptografar valor numérico: $e');
      debugPrint('❌ Valor problemático: $encryptedValue');
      
      // Se for um erro crítico de chave, marcar para reinicialização
      if (e.toString().contains('Invalid key') || e.toString().contains('key')) {
        debugPrint('🔄 Erro de chave detectado, marcando para reinicialização...');
        _error = 'Erro de chave de criptografia - reinicialização necessária';
        _isEncryptionEnabled = false;
        notifyListeners();
      }
      
      return double.tryParse(encryptedValue) ?? 0.0;
    }
  }

  /// Verifica se um campo está criptografado
  bool isFieldEncrypted(String data) {
    return EncryptionService.isEncrypted(data);
  }

  /// Limpa as chaves de criptografia (logout)
  Future<void> clearEncryption() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await EncryptionService.clearUserKeys(user.id);
      }
      
      _userEncryptionKey = null;
      _isEncryptionEnabled = false;
      _isInitialized = false;
      _error = null;
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Habilita/desabilita a criptografia
  void toggleEncryption(bool enabled) {
    _isEncryptionEnabled = enabled;
    notifyListeners();
  }

  /// Método para migrar dados existentes (criptografar dados não criptografados)
  String migrateField(String data) {
    if (data.isEmpty) return data;
    
    // Se já está criptografado, retorna como está
    if (isFieldEncrypted(data)) {
      return data;
    }
    
    // Se não está criptografado, criptografa agora
    return encryptField(data);
  }

  /// Método para migrar valores numéricos
  String migrateNumericField(dynamic value) {
    if (value == null) return '0';
    
    String stringValue = value.toString();
    
    // Se já está criptografado, retorna como está
    if (isFieldEncrypted(stringValue)) {
      return stringValue;
    }
    
    // Se não está criptografado, criptografa agora
    double numericValue = double.tryParse(stringValue) ?? 0.0;
    return encryptNumericField(numericValue);
  }
}
