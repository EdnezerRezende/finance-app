# Guia de Criptografia - Sistema de Finanças Pessoais

## Visão Geral

Este sistema implementa criptografia client-side AES-256 para proteger dados financeiros sensíveis. Os dados são criptografados no dispositivo antes de serem enviados ao Supabase, garantindo que apenas o usuário tenha acesso aos dados descriptografados.

## Componentes Implementados

### 1. EncryptionService (`lib/services/encryption_service.dart`)
- **Algoritmo**: AES-256 com IV único por campo
- **Derivação de chave**: PBKDF2 com salt único por usuário
- **Formato**: `iv:encrypted_data` (Base64)
- **Detecção automática**: Identifica dados já criptografados

### 2. EncryptionProvider (`lib/providers/encryption_provider.dart`)
- Gerenciamento de estado da criptografia
- Inicialização automática baseada no usuário logado
- Métodos convenientes para criptografar/descriptografar
- Suporte a migração de dados existentes

### 3. Modelos Atualizados
- **Transaction**: Métodos `toSupabaseEncrypted()` e `fromSupabaseEncrypted()`
- Suporte transparente a criptografia nos modelos

## Como Usar

### Inicialização
```dart
// No main.dart - já configurado
ChangeNotifierProvider(create: (context) => EncryptionProvider()),

// No HomeScreen - já configurado
final encryptionProvider = Provider.of<EncryptionProvider>(context, listen: false);
await encryptionProvider.initializeEncryption();
```

### Nos Providers
```dart
class TransactionProvider with ChangeNotifier {
  EncryptionProvider? _encryptionProvider;

  void setEncryptionProvider(EncryptionProvider encryptionProvider) {
    _encryptionProvider = encryptionProvider;
  }

  // Ao carregar dados
  if (_encryptionProvider?.isEncryptionEnabled == true) {
    _transactions = data.map((json) => Transaction.fromSupabaseEncrypted(
      json, 
      _encryptionProvider!.decryptField, 
      _encryptionProvider!.decryptNumericField
    )).toList();
  } else {
    _transactions = data.map((json) => Transaction.fromSupabase(json)).toList();
  }

  // Ao salvar dados
  Map<String, dynamic> transactionData;
  if (_encryptionProvider?.isEncryptionEnabled == true) {
    transactionData = newTransaction.toSupabaseEncrypted(
      _encryptionProvider!.encryptField,
      _encryptionProvider!.encryptNumericField
    );
  } else {
    transactionData = newTransaction.toSupabase();
  }
}
```

## Campos Criptografados

### Transações (expense)
- `description` - Descrição da transação
- `amount` - Valor da transação

### Financiamentos (finances)
- `tipo` - Tipo do financiamento
- `valorTotal` - Valor total
- `saldoDevedor` - Saldo devedor
- `valorDesconto` - Valor do desconto
- `valorPago` - Valor pago

### Cartões de Crédito (credit_cards)
- `name` - Nome do cartão
- `creditLimit` - Limite de crédito
- `currentBalance` - Saldo atual

### Parcelas (cartao)
- `description` - Descrição da parcela
- `valor` - Valor da parcela

### Compras (purchases)
- `description` - Descrição da compra
- `amount` - Valor da compra

## Migração de Dados Existentes

### Detecção Automática
O sistema detecta automaticamente dados não criptografados:
```dart
// Dados criptografados têm formato: "iv:encrypted_data"
bool isEncrypted = data.contains(':') && data.split(':').length == 2;
```

### Estratégia de Migração
1. **Compatibilidade**: Dados antigos continuam funcionando
2. **Migração gradual**: Novos dados são automaticamente criptografados
3. **Migração manual**: Use os métodos `migrateField()` e `migrateNumericField()`

### Exemplo de Migração
```dart
// Para migrar dados existentes
String migratedDescription = encryptionProvider.migrateField(oldDescription);
String migratedAmount = encryptionProvider.migrateNumericField(oldAmount);
```

## Segurança

### Geração de Chaves
- **PBKDF2**: 10.000 iterações
- **Salt único**: 16 bytes por usuário
- **Chave**: 256 bits (32 bytes)

### Armazenamento
- **Chaves**: Armazenadas localmente com SharedPreferences
- **Salt**: Persistido por usuário
- **Limpeza**: Chaves removidas no logout

### Senha Temporária
Por enquanto, usa uma derivação do email do usuário. Em produção, deve usar a senha real:
```dart
// Atual (temporário)
String tempPassword = EncryptionService.generateTempPassword(userEmail);

// Produção (implementar)
String userPassword = await getUserRealPassword();
```

## Implementação em Outros Providers

Para adicionar criptografia a outros providers:

1. **Adicionar referência ao EncryptionProvider**:
```dart
EncryptionProvider? _encryptionProvider;
void setEncryptionProvider(EncryptionProvider encryptionProvider) {
  _encryptionProvider = encryptionProvider;
}
```

2. **Atualizar métodos de carregamento**:
```dart
if (_encryptionProvider?.isEncryptionEnabled == true) {
  // Usar métodos de descriptografia
} else {
  // Usar métodos normais
}
```

3. **Atualizar métodos de salvamento**:
```dart
if (_encryptionProvider?.isEncryptionEnabled == true) {
  // Usar métodos de criptografia
} else {
  // Usar métodos normais
}
```

## Próximos Passos

1. **Executar `flutter pub get`** para instalar dependências
2. **Testar com dados existentes** para verificar compatibilidade
3. **Implementar nos demais providers** (CreditCardProvider, FinanceProvider, etc.)
4. **Configurar senha real do usuário** em produção
5. **Criar script de migração em massa** se necessário

## Troubleshooting

### Erro de Descriptografia
- Verifique se a chave está correta
- Dados podem não estar criptografados (migração)
- Verificar formato dos dados (`iv:encrypted_data`)

### Performance
- Criptografia é feita em lotes pequenos
- Considere cache para dados frequentemente acessados
- Monitor uso de memória com grandes volumes

### Backup
- **IMPORTANTE**: Faça backup antes de ativar criptografia
- Dados criptografados são irrecuperáveis sem a chave
- Considere exportação de dados descriptografados
