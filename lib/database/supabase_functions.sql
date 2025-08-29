-- =====================================================
-- FUNÇÕES E STORED PROCEDURES PARA CARTÃO DE CRÉDITO
-- =====================================================

-- =====================================================
-- FUNÇÃO: Criar parcelas automaticamente
-- =====================================================
CREATE OR REPLACE FUNCTION create_installments_for_purchase(
    p_purchase_id UUID,
    p_user_id UUID,
    p_credit_card_id UUID,
    p_total_amount DECIMAL(15,2),
    p_installments_count INTEGER,
    p_first_installment_date DATE
)
RETURNS VOID AS $$
DECLARE
    installment_amount DECIMAL(15,2);
    current_date DATE;
    i INTEGER;
BEGIN
    -- Calcular valor da parcela
    installment_amount := p_total_amount / p_installments_count;
    current_date := p_first_installment_date;
    
    -- Criar as parcelas
    FOR i IN 1..p_installments_count LOOP
        INSERT INTO installments (
            user_id,
            purchase_id,
            credit_card_id,
            installment_number,
            amount,
            original_amount,
            due_date,
            status
        ) VALUES (
            p_user_id,
            p_purchase_id,
            p_credit_card_id,
            i,
            installment_amount,
            installment_amount,
            current_date,
            'pending'
        );
        
        -- Próxima data (adicionar 1 mês)
        current_date := current_date + INTERVAL '1 month';
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNÇÃO: Atualizar saldo do cartão
-- =====================================================
CREATE OR REPLACE FUNCTION update_credit_card_balance(p_credit_card_id UUID)
RETURNS VOID AS $$
DECLARE
    total_pending DECIMAL(15,2);
    card_limit DECIMAL(15,2);
BEGIN
    -- Calcular total de parcelas pendentes
    SELECT COALESCE(SUM(amount), 0) INTO total_pending
    FROM installments
    WHERE credit_card_id = p_credit_card_id 
    AND status = 'pending';
    
    -- Buscar limite do cartão
    SELECT credit_limit INTO card_limit
    FROM credit_cards
    WHERE id = p_credit_card_id;
    
    -- Atualizar saldos
    UPDATE credit_cards
    SET 
        current_balance = total_pending,
        available_limit = card_limit - total_pending,
        updated_at = NOW()
    WHERE id = p_credit_card_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNÇÃO: Pagar parcela
-- =====================================================
CREATE OR REPLACE FUNCTION pay_installment(
    p_installment_id UUID,
    p_payment_amount DECIMAL(15,2),
    p_payment_method VARCHAR(50) DEFAULT 'manual',
    p_payment_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    installment_card_id UUID;
    payment_successful BOOLEAN := FALSE;
BEGIN
    -- Buscar ID do cartão
    SELECT credit_card_id INTO installment_card_id
    FROM installments
    WHERE id = p_installment_id;
    
    -- Atualizar a parcela
    UPDATE installments
    SET 
        status = 'paid',
        payment_date = CURRENT_DATE,
        payment_amount = p_payment_amount,
        payment_method = p_payment_method,
        payment_notes = p_payment_notes,
        updated_at = NOW()
    WHERE id = p_installment_id
    AND status = 'pending';
    
    -- Verificar se a atualização foi bem-sucedida
    IF FOUND THEN
        payment_successful := TRUE;
        
        -- Atualizar saldo do cartão
        PERFORM update_credit_card_balance(installment_card_id);
    END IF;
    
    RETURN payment_successful;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNÇÃO: Calcular próximas parcelas vencendo
-- =====================================================
CREATE OR REPLACE FUNCTION get_upcoming_installments(
    p_user_id UUID,
    p_days_ahead INTEGER DEFAULT 7
)
RETURNS TABLE(
    installment_id UUID,
    credit_card_name VARCHAR(100),
    purchase_description VARCHAR(255),
    installment_number INTEGER,
    total_installments INTEGER,
    amount DECIMAL(15,2),
    due_date DATE,
    days_until_due INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id as installment_id,
        cc.card_name as credit_card_name,
        p.description as purchase_description,
        i.installment_number,
        p.installments_count as total_installments,
        i.amount,
        i.due_date,
        (i.due_date - CURRENT_DATE)::INTEGER as days_until_due
    FROM installments i
    JOIN purchases p ON i.purchase_id = p.id
    JOIN credit_cards cc ON i.credit_card_id = cc.id
    WHERE i.user_id = p_user_id
    AND i.status = 'pending'
    AND i.due_date BETWEEN CURRENT_DATE AND (CURRENT_DATE + p_days_ahead)
    ORDER BY i.due_date, cc.card_name, p.description;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNÇÃO: Relatório de gastos por categoria
-- =====================================================
CREATE OR REPLACE FUNCTION get_expenses_by_category(
    p_user_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE(
    category_name VARCHAR(100),
    total_amount DECIMAL(15,2),
    installments_count BIGINT,
    purchases_count BIGINT
) AS $$
BEGIN
    -- Se as datas não forem fornecidas, usar o mês atual
    IF p_start_date IS NULL THEN
        p_start_date := DATE_TRUNC('month', CURRENT_DATE);
    END IF;
    
    IF p_end_date IS NULL THEN
        p_end_date := DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day';
    END IF;
    
    RETURN QUERY
    SELECT 
        COALESCE(p.category, 'Sem Categoria') as category_name,
        SUM(i.amount) as total_amount,
        COUNT(i.id) as installments_count,
        COUNT(DISTINCT p.id) as purchases_count
    FROM installments i
    JOIN purchases p ON i.purchase_id = p.id
    WHERE i.user_id = p_user_id
    AND i.due_date BETWEEN p_start_date AND p_end_date
    GROUP BY p.category
    ORDER BY total_amount DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNÇÃO: Resumo do cartão de crédito
-- =====================================================
CREATE OR REPLACE FUNCTION get_credit_card_summary(p_credit_card_id UUID)
RETURNS TABLE(
    card_name VARCHAR(100),
    credit_limit DECIMAL(15,2),
    current_balance DECIMAL(15,2),
    available_limit DECIMAL(15,2),
    pending_installments BIGINT,
    next_due_date DATE,
    next_due_amount DECIMAL(15,2),
    overdue_installments BIGINT,
    overdue_amount DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cc.card_name,
        cc.credit_limit,
        cc.current_balance,
        cc.available_limit,
        COUNT(i.id) FILTER (WHERE i.status = 'pending') as pending_installments,
        MIN(i.due_date) FILTER (WHERE i.status = 'pending' AND i.due_date >= CURRENT_DATE) as next_due_date,
        SUM(i.amount) FILTER (WHERE i.status = 'pending' AND i.due_date = (
            SELECT MIN(i2.due_date) 
            FROM installments i2 
            WHERE i2.credit_card_id = p_credit_card_id 
            AND i2.status = 'pending' 
            AND i2.due_date >= CURRENT_DATE
        )) as next_due_amount,
        COUNT(i.id) FILTER (WHERE i.status = 'pending' AND i.due_date < CURRENT_DATE) as overdue_installments,
        SUM(i.amount) FILTER (WHERE i.status = 'pending' AND i.due_date < CURRENT_DATE) as overdue_amount
    FROM credit_cards cc
    LEFT JOIN installments i ON cc.id = i.credit_card_id
    WHERE cc.id = p_credit_card_id
    GROUP BY cc.id, cc.card_name, cc.credit_limit, cc.current_balance, cc.available_limit;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNÇÃO: Marcar parcelas em atraso
-- =====================================================
CREATE OR REPLACE FUNCTION mark_overdue_installments()
RETURNS INTEGER AS $$
DECLARE
    affected_rows INTEGER;
BEGIN
    UPDATE installments
    SET status = 'overdue'
    WHERE status = 'pending'
    AND due_date < CURRENT_DATE;
    
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RETURN affected_rows;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VIEW: Parcelas com informações detalhadas
-- =====================================================
CREATE OR REPLACE VIEW installments_detailed AS
SELECT 
    i.id,
    i.user_id,
    i.installment_number,
    i.amount,
    i.due_date,
    i.payment_date,
    i.status,
    i.payment_amount,
    i.payment_method,
    p.description as purchase_description,
    p.total_amount as purchase_total,
    p.installments_count as total_installments,
    p.category,
    p.merchant_name,
    cc.card_name,
    cc.card_number_masked,
    -- Calcular dias até vencimento
    CASE 
        WHEN i.status = 'pending' THEN (i.due_date - CURRENT_DATE)::INTEGER
        ELSE NULL
    END as days_until_due,
    -- Indicar se está em atraso
    CASE 
        WHEN i.status = 'pending' AND i.due_date < CURRENT_DATE THEN TRUE
        ELSE FALSE
    END as is_overdue
FROM installments i
JOIN purchases p ON i.purchase_id = p.id
JOIN credit_cards cc ON i.credit_card_id = cc.id;

-- =====================================================
-- VIEW: Resumo mensal por cartão
-- =====================================================
CREATE OR REPLACE VIEW monthly_card_summary AS
SELECT 
    cc.id as credit_card_id,
    cc.card_name,
    DATE_TRUNC('month', i.due_date) as month_year,
    COUNT(i.id) as total_installments,
    COUNT(i.id) FILTER (WHERE i.status = 'paid') as paid_installments,
    COUNT(i.id) FILTER (WHERE i.status = 'pending') as pending_installments,
    COUNT(i.id) FILTER (WHERE i.status = 'overdue') as overdue_installments,
    SUM(i.amount) as total_amount,
    SUM(i.amount) FILTER (WHERE i.status = 'paid') as paid_amount,
    SUM(i.amount) FILTER (WHERE i.status = 'pending') as pending_amount,
    SUM(i.amount) FILTER (WHERE i.status = 'overdue') as overdue_amount
FROM credit_cards cc
LEFT JOIN installments i ON cc.id = i.credit_card_id
GROUP BY cc.id, cc.card_name, DATE_TRUNC('month', i.due_date)
ORDER BY cc.card_name, month_year DESC;