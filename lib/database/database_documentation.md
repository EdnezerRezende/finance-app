# Documentação do Banco de Dados - Controle de Cartão de Crédito

## Visão Geral

Este sistema foi projetado para controlar parcelas e gastos de cartões de crédito de forma completa e robusta, incluindo todas as funcionalidades necessárias para um controle financeiro eficiente.

## Estrutura das Tabelas

### 1. `credit_cards` - Cartões de Crédito

**Finalidade**: Armazena informações dos cartões de crédito do usuário.

**Campos Importantes**:
- `card_name`: Nome do cartão (ex: "Nubank Roxinho")
- `card_number_masked`: Número mascarado para segurança
- `credit_limit`: Limite total do cartão
- `available_limit`: Limite disponível (calculado automaticamente)
- `current_balance`: Saldo atual usado
- `closing_day`/`due_day`: Dias de fechamento e vencimento da fatura

**Funcionalidades**:
- Múltiplos cartões por usuário
- Controle de limites em tempo real
- Configuração de cores para identificação visual

### 2. `purchases` - Compras

**Finalidade**: Registra cada compra realizada no cartão.

**Campos Importantes**:
- `description`: Descrição da compra
- `total_amount`: Valor total da compra
- `installments_count`: Quantidade de parcelas
- `installment_amount`: Valor de cada parcela
- `category`: Categoria do gasto
- `merchant_name`: Nome do estabelecimento

**Funcionalidades**:
- Parcelamento automático
- Categorização de gastos
- Histórico completo de compras

### 3. `installments` - Parcelas

**Finalidade**: Controla cada parcela individualmente.

**Campos Importantes**:
- `installment_number`: Número da parcela (1/12, 2/12, etc.)
- `amount`: Valor da parcela
- `due_date`: Data de vencimento
- `status`: Status (pending, paid, overdue, cancelled)
- `payment_date`: Data do pagamento
- `payment_amount`: Valor pago (pode diferir do valor original)

**Funcionalidades**:
- Controle individual de cada parcela
- Histórico de pagamentos
- Cálculo de juros e multas
- Status de vencimento automático

### 4. `credit_card_statements` - Faturas

**Finalidade**: Controla as faturas mensais do cartão.

**Campos Importantes**:
- `statement_date`: Data da fatura
- `due_date`: Data de vencimento
- `total_amount`: Valor total da fatura
- `minimum_payment`: Valor mínimo
- `status`: Status da fatura

### 5. `expense_categories` - Categorias

**Finalidade**: Organiza os gastos por categorias.

**Funcionalidades**:
- Hierarquia de categorias (pai/filho)
- Controle de orçamento por categoria
- Personalização visual (cores e ícones)

### 6. `payment_alerts` - Alertas

**Finalidade**: Sistema de notificações para vencimentos.

**Funcionalidades**:
- Alertas automáticos
- Configuração de dias de antecedência
- Múltiplos tipos de alerta

## Funcionalidades Principais

### 1. **Controle de Parcelas**
- ✅ Criação automática de parcelas
- ✅ Acompanhamento individual de cada parcela
- ✅ Status de pagamento (pendente, pago, vencido)
- ✅ Histórico completo de pagamentos

### 2. **Gestão de Limites**
- ✅ Cálculo automático do limite disponível
- ✅ Atualização em tempo real após pagamentos
- ✅ Controle de múltiplos cartões

### 3. **Categorização**
- ✅ Categorias personalizáveis
- ✅ Hierarquia de categorias
- ✅ Relatórios por categoria
- ✅ Controle de orçamento

### 4. **Relatórios e Análises**
- ✅ Gastos por categoria
- ✅ Resumo mensal por cartão
- ✅ Parcelas vencendo
- ✅ Histórico de pagamentos

### 5. **Alertas e Notificações**
- ✅ Alertas de vencimento
- ✅ Notificações de atraso
- ✅ Lembretes de faturas

## Recursos Avançados Incluídos

### 1. **Segurança**
- RLS (Row Level Security) em todas as tabelas
- Políticas de acesso por usuário
- Máscaramento de dados sensíveis

### 2. **Performance**
- Índices otimizados para consultas frequentes
- Views materializadas para relatórios
- Queries otimizadas

### 3. **Auditoria**
- Timestamps automáticos (created_at, updated_at)
- Histórico de alterações
- Triggers automáticos

### 4. **Validações**
- Constraints de integridade
- Validações de valores
- Consistência de dados

## Funções Especiais

### 1. `create_installments_for_purchase()`
Cria automaticamente as parcelas quando uma compra é registrada.

### 2. `update_credit_card_balance()`
Atualiza o saldo e limite disponível do cartão automaticamente.

### 3. `pay_installment()`
Processa o pagamento de uma parcela e atualiza os saldos.

### 4. `get_upcoming_installments()`
Retorna as próximas parcelas a vencer.

### 5. `get_expenses_by_category()`
Gera relatório de gastos por categoria.

## Views Úteis

### 1. `installments_detailed`
Parcelas com todas as informações detalhadas.

### 2. `monthly_card_summary`
Resumo mensal por cartão com estatísticas.

## Como Usar

### 1. **Registrar um Cartão**
```sql
INSERT INTO credit_cards (user_id, card_name, credit_limit, closing_day, due_day)
VALUES (auth.uid(), 'Meu Cartão', 5000.00, 10, 17);
```

### 2. **Registrar uma Compra Parcelada**
```sql
-- 1. Inserir a compra
INSERT INTO purchases (user_id, credit_card_id, description, total_amount, installments_count, installment_amount, first_installment_date)
VALUES (auth.uid(), 'card_id', 'Notebook', 2400.00, 12, 200.00, '2025-02-01');

-- 2. Criar as parcelas automaticamente
SELECT create_installments_for_purchase(purchase_id, auth.uid(), card_id, 2400.00, 12, '2025-02-01');
```

### 3. **Pagar uma Parcela**
```sql
SELECT pay_installment('installment_id', 200.00, 'pix', 'Pagamento via PIX');
```

### 4. **Consultar Próximos Vencimentos**
```sql
SELECT * FROM get_upcoming_installments(auth.uid(), 7); -- Próximos 7 dias
```

## Campos Adicionais Sugeridos

Além do que você mencionou, incluí campos importantes como:

1. **Juros e Multas**: Para casos de atraso
2. **Método de Pagamento**: Como foi pago (PIX, transferência, etc.)
3. **Categorização**: Para organizar os gastos
4. **Alertas**: Sistema de notificações
5. **Faturas**: Controle das faturas mensais
6. **Merchant**: Nome do estabelecimento
7. **Localização**: Onde foi feita a compra
8. **Observações**: Campos de texto livre
9. **Status Detalhado**: Estados mais específicos
10. **Auditoria**: Timestamps e histórico

Esta estrutura permite um controle completo e profissional dos cartões de crédito e suas parcelas!