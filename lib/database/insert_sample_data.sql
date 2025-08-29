-- =====================================================
-- DADOS DE EXEMPLO PARA TESTES
-- =====================================================

-- NOTA: Substitua 'SEU_USER_ID' pelo UUID real do usuário

-- =====================================================
-- INSERIR CATEGORIAS DE EXEMPLO
-- =====================================================
INSERT INTO expense_categories (user_id, name, description, color, icon) VALUES
('SEU_USER_ID', 'Alimentação', 'Gastos com comida e bebida', '#4CAF50', 'restaurant'),
('SEU_USER_ID', 'Transporte', 'Combustível, Uber, transporte público', '#2196F3', 'directions_car'),
('SEU_USER_ID', 'Saúde', 'Farmácia, consultas, exames', '#F44336', 'local_hospital'),
('SEU_USER_ID', 'Educação', 'Cursos, livros, material escolar', '#FF9800', 'school'),
('SEU_USER_ID', 'Lazer', 'Cinema, jogos, entretenimento', '#9C27B0', 'movie'),
('SEU_USER_ID', 'Casa', 'Móveis, decoração, manutenção', '#795548', 'home'),
('SEU_USER_ID', 'Roupas', 'Vestuário e acessórios', '#E91E63', 'shopping_bag'),
('SEU_USER_ID', 'Tecnologia', 'Eletrônicos, gadgets, software', '#607D8B', 'computer');

-- =====================================================
-- INSERIR CARTÕES DE EXEMPLO
-- =====================================================
INSERT INTO credit_cards (user_id, card_name, card_number_masked, bank_name, credit_limit, available_limit, current_balance, closing_day, due_day, card_color) VALUES
('SEU_USER_ID', 'Nubank Roxinho', '**** **** **** 1234', 'Nubank', 5000.00, 3500.00, 1500.00, 10, 17, '#8A05BE'),
('SEU_USER_ID', 'Inter Black', '**** **** **** 5678', 'Banco Inter', 8000.00, 6200.00, 1800.00, 15, 22, '#000000'),
('SEU_USER_ID', 'C6 Carbon', '**** **** **** 9012', 'C6 Bank', 3000.00, 2100.00, 900.00, 5, 12, '#1A1A1A');

-- =====================================================
-- INSERIR COMPRAS DE EXEMPLO
-- =====================================================

-- Compra 1: Notebook parcelado em 12x
INSERT INTO purchases (user_id, credit_card_id, description, total_amount, installments_count, installment_amount, category, merchant_name, purchase_date, first_installment_date) 
VALUES (
    'SEU_USER_ID', 
    (SELECT id FROM credit_cards WHERE card_name = 'Nubank Roxinho' AND user_id = 'SEU_USER_ID'), 
    'Notebook Dell Inspiron 15', 
    2400.00, 
    12, 
    200.00, 
    'Tecnologia', 
    'Mercado Livre', 
    '2025-01-15', 
    '2025-02-17'
);

-- Compra 2: Curso online parcelado em 6x
INSERT INTO purchases (user_id, credit_card_id, description, total_amount, installments_count, installment_amount, category, merchant_name, purchase_date, first_installment_date)
VALUES (
    'SEU_USER_ID',
    (SELECT id FROM credit_cards WHERE card_name = 'Inter Black' AND user_id = 'SEU_USER_ID'),
    'Curso de Flutter Avançado',
    600.00,
    6,
    100.00,
    'Educação',
    'Udemy',
    '2025-01-10',
    '2025-02-22'
);

-- Compra 3: Geladeira parcelada em 10x
INSERT INTO purchases (user_id, credit_card_id, description, total_amount, installments_count, installment_amount, category, merchant_name, purchase_date, first_installment_date)
VALUES (
    'SEU_USER_ID',
    (SELECT id FROM credit_cards WHERE card_name = 'C6 Carbon' AND user_id = 'SEU_USER_ID'),
    'Geladeira Brastemp Frost Free 400L',
    1800.00,
    10,
    180.00,
    'Casa',
    'Casas Bahia',
    '2025-01-08',
    '2025-02-12'
);

-- Compra 4: Tênis à vista
INSERT INTO purchases (user_id, credit_card_id, description, total_amount, installments_count, installment_amount, category, merchant_name, purchase_date, first_installment_date)
VALUES (
    'SEU_USER_ID',
    (SELECT id FROM credit_cards WHERE card_name = 'Nubank Roxinho' AND user_id = 'SEU_USER_ID'),
    'Tênis Nike Air Max',
    350.00,
    1,
    350.00,
    'Roupas',
    'Nike Store',
    '2025-01-20',
    '2025-02-17'
);

-- =====================================================
-- CRIAR PARCELAS AUTOMATICAMENTE
-- =====================================================

-- Criar parcelas para o Notebook (12x)
SELECT create_installments_for_purchase(
    (SELECT id FROM purchases WHERE description = 'Notebook Dell Inspiron 15' AND user_id = 'SEU_USER_ID'),
    'SEU_USER_ID',
    (SELECT id FROM credit_cards WHERE card_name = 'Nubank Roxinho' AND user_id = 'SEU_USER_ID'),
    2400.00,
    12,
    '2025-02-17'
);

-- Criar parcelas para o Curso (6x)
SELECT create_installments_for_purchase(
    (SELECT id FROM purchases WHERE description = 'Curso de Flutter Avançado' AND user_id = 'SEU_USER_ID'),
    'SEU_USER_ID',
    (SELECT id FROM credit_cards WHERE card_name = 'Inter Black' AND user_id = 'SEU_USER_ID'),
    600.00,
    6,
    '2025-02-22'
);

-- Criar parcelas para a Geladeira (10x)
SELECT create_installments_for_purchase(
    (SELECT id FROM purchases WHERE description = 'Geladeira Brastemp Frost Free 400L' AND user_id = 'SEU_USER_ID'),
    'SEU_USER_ID',
    (SELECT id FROM credit_cards WHERE card_name = 'C6 Carbon' AND user_id = 'SEU_USER_ID'),
    1800.00,
    10,
    '2025-02-12'
);

-- Criar parcela para o Tênis (1x)
SELECT create_installments_for_purchase(
    (SELECT id FROM purchases WHERE description = 'Tênis Nike Air Max' AND user_id = 'SEU_USER_ID'),
    'SEU_USER_ID',
    (SELECT id FROM credit_cards WHERE card_name = 'Nubank Roxinho' AND user_id = 'SEU_USER_ID'),
    350.00,
    1,
    '2025-02-17'
);

-- =====================================================
-- PAGAR ALGUMAS PARCELAS PARA DEMONSTRAÇÃO
-- =====================================================

-- Pagar primeira parcela do notebook
SELECT pay_installment(
    (SELECT id FROM installments WHERE installment_number = 1 AND purchase_id = (
        SELECT id FROM purchases WHERE description = 'Notebook Dell Inspiron 15' AND user_id = 'SEU_USER_ID'
    )),
    200.00,
    'pix',
    'Pagamento via PIX - Primeira parcela'
);

-- Pagar parcela do tênis (à vista)
SELECT pay_installment(
    (SELECT id FROM installments WHERE installment_number = 1 AND purchase_id = (
        SELECT id FROM purchases WHERE description = 'Tênis Nike Air Max' AND user_id = 'SEU_USER_ID'
    )),
    350.00,
    'credito',
    'Compra à vista no cartão'
);

-- =====================================================
-- ATUALIZAR SALDOS DOS CARTÕES
-- =====================================================

-- Atualizar saldos de todos os cartões
SELECT update_credit_card_balance(id) FROM credit_cards WHERE user_id = 'SEU_USER_ID';

-- =====================================================
-- CONSULTAS ÚTEIS PARA TESTAR
-- =====================================================

-- Ver todas as parcelas pendentes
-- SELECT * FROM installments_detailed WHERE user_id = 'SEU_USER_ID' AND status = 'pending' ORDER BY due_date;

-- Ver próximas parcelas vencendo (próximos 30 dias)
-- SELECT * FROM get_upcoming_installments('SEU_USER_ID', 30);

-- Ver resumo dos cartões
-- SELECT * FROM get_credit_card_summary(id) FROM credit_cards WHERE user_id = 'SEU_USER_ID';

-- Ver gastos por categoria (mês atual)
-- SELECT * FROM get_expenses_by_category('SEU_USER_ID');

-- Ver resumo mensal
-- SELECT * FROM monthly_card_summary WHERE credit_card_id IN (SELECT id FROM credit_cards WHERE user_id = 'SEU_USER_ID');