-- Triggers para criar notificações automaticamente

-- Função para criar notificação de vencimento de despesa
CREATE OR REPLACE FUNCTION create_expense_due_notification()
RETURNS TRIGGER AS $$
DECLARE
    days_until_due INTEGER;
    notification_exists BOOLEAN;
BEGIN
    -- Verificar se a despesa tem data de vencimento
    IF NEW.due_date IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Calcular dias até o vencimento
    days_until_due := (NEW.due_date::date - CURRENT_DATE);
    
    -- Criar notificação apenas se vencer em 1 ou 3 dias
    IF days_until_due IN (1, 3) THEN
        -- Verificar se já existe notificação para esta despesa e data
        SELECT EXISTS(
            SELECT 1 FROM notifications 
            WHERE user_id = NEW.user_id 
            AND type = 'expense_due'
            AND data->>'expense_id' = NEW.id::text
            AND data->>'due_date' = NEW.due_date::text
        ) INTO notification_exists;
        
        -- Criar notificação apenas se não existir
        IF NOT notification_exists THEN
            INSERT INTO notifications (
                user_id,
                group_id,
                type,
                title,
                message,
                data,
                expires_at
            ) VALUES (
                NEW.user_id,
                NEW.group_id,
                'expense_due',
                'Despesa a vencer',
                CASE 
                    WHEN days_until_due = 1 THEN 
                        'A despesa "' || COALESCE(NEW.description, 'Sem descrição') || '" vence amanhã'
                    ELSE 
                        'A despesa "' || COALESCE(NEW.description, 'Sem descrição') || '" vence em ' || days_until_due || ' dias'
                END,
                jsonb_build_object(
                    'expense_id', NEW.id,
                    'expense_description', COALESCE(NEW.description, 'Sem descrição'),
                    'due_date', NEW.due_date,
                    'amount', NEW.amount,
                    'days_until_due', days_until_due
                ),
                NEW.due_date + INTERVAL '1 day'
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Função para criar notificação de vencimento de cartão de crédito
CREATE OR REPLACE FUNCTION create_credit_card_due_notification()
RETURNS TRIGGER AS $$
DECLARE
    days_until_due INTEGER;
    notification_exists BOOLEAN;
    card_name TEXT;
BEGIN
    -- Verificar se o cartão tem data de vencimento
    IF NEW.due_date IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Calcular dias até o vencimento
    days_until_due := (NEW.due_date::date - CURRENT_DATE);
    
    -- Obter nome do cartão
    card_name := COALESCE(NEW.name, 'Cartão sem nome');
    
    -- Criar notificação apenas se vencer em 1, 3 ou 7 dias
    IF days_until_due IN (1, 3, 7) THEN
        -- Verificar se já existe notificação para este cartão e data
        SELECT EXISTS(
            SELECT 1 FROM notifications 
            WHERE user_id = NEW.user_id 
            AND type = 'credit_card_due'
            AND data->>'card_id' = NEW.id::text
            AND data->>'due_date' = NEW.due_date::text
        ) INTO notification_exists;
        
        -- Criar notificação apenas se não existir
        IF NOT notification_exists THEN
            INSERT INTO notifications (
                user_id,
                group_id,
                type,
                title,
                message,
                data,
                expires_at
            ) VALUES (
                NEW.user_id,
                NEW.group_id,
                'credit_card_due',
                'Fatura de cartão a vencer',
                CASE 
                    WHEN days_until_due = 1 THEN 
                        'A fatura do cartão "' || card_name || '" vence amanhã'
                    ELSE 
                        'A fatura do cartão "' || card_name || '" vence em ' || days_until_due || ' dias'
                END,
                jsonb_build_object(
                    'card_id', NEW.id,
                    'card_name', card_name,
                    'due_date', NEW.due_date,
                    'amount', COALESCE(NEW.limit_amount, 0),
                    'days_until_due', days_until_due
                ),
                NEW.due_date + INTERVAL '3 days'
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Função para criar notificação de vencimento de financiamento
CREATE OR REPLACE FUNCTION create_finance_due_notification()
RETURNS TRIGGER AS $$
DECLARE
    days_until_due INTEGER;
    notification_exists BOOLEAN;
    next_due_date DATE;
BEGIN
    -- Calcular próxima data de vencimento baseada nas parcelas pagas
    -- Assumindo que é mensal e começou na data de criação
    next_due_date := (NEW.created_at::date + INTERVAL '1 month' * COALESCE(array_length(NEW.parcelas_quitadas, 1), 0))::date;
    
    -- Verificar se ainda há parcelas a pagar
    IF COALESCE(array_length(NEW.parcelas_quitadas, 1), 0) >= COALESCE(NEW.quantidade_parcelas, 0) THEN
        RETURN NEW;
    END IF;
    
    -- Calcular dias até o vencimento
    days_until_due := (next_due_date - CURRENT_DATE);
    
    -- Criar notificação apenas se vencer em 1 ou 3 dias
    IF days_until_due IN (1, 3) THEN
        -- Verificar se já existe notificação para este financiamento e data
        SELECT EXISTS(
            SELECT 1 FROM notifications 
            WHERE user_id = NEW.user_id 
            AND type = 'finance_due'
            AND data->>'finance_id' = NEW.id::text
            AND data->>'due_date' = next_due_date::text
        ) INTO notification_exists;
        
        -- Criar notificação apenas se não existir
        IF NOT notification_exists THEN
            INSERT INTO notifications (
                user_id,
                group_id,
                type,
                title,
                message,
                data,
                expires_at
            ) VALUES (
                NEW.user_id,
                NEW.group_id,
                'finance_due',
                'Parcela de financiamento a vencer',
                CASE 
                    WHEN days_until_due = 1 THEN 
                        'A parcela do ' || NEW.tipo || ' vence amanhã'
                    ELSE 
                        'A parcela do ' || NEW.tipo || ' vence em ' || days_until_due || ' dias'
                END,
                jsonb_build_object(
                    'finance_id', NEW.id,
                    'finance_type', NEW.tipo,
                    'due_date', next_due_date,
                    'amount', COALESCE(NEW.valor_total, 0) / COALESCE(NEW.quantidade_parcelas, 1),
                    'days_until_due', days_until_due,
                    'installment_number', COALESCE(array_length(NEW.parcelas_quitadas, 1), 0) + 1
                ),
                next_due_date + INTERVAL '1 day'
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Função para criar notificação de convite para grupo
CREATE OR REPLACE FUNCTION create_group_invite_notification()
RETURNS TRIGGER AS $$
DECLARE
    group_name TEXT;
    inviter_name TEXT;
    inviter_email TEXT;
BEGIN
    -- Verificar se é um novo membro pendente
    IF NEW.status != 'pending' THEN
        RETURN NEW;
    END IF;
    
    -- Obter nome do grupo
    SELECT name INTO group_name 
    FROM groups 
    WHERE id = NEW.group_id;
    
    -- Obter informações do usuário que fez o convite
    -- Como não temos essa informação diretamente, usar o criador do grupo
    SELECT u.email INTO inviter_email
    FROM groups g
    JOIN auth.users u ON g.created_by = u.id
    WHERE g.id = NEW.group_id;
    
    inviter_name := COALESCE(inviter_email, 'Usuário');
    
    -- Criar notificação de convite
    INSERT INTO notifications (
        user_id,
        group_id,
        type,
        title,
        message,
        data,
        expires_at
    ) VALUES (
        NEW.user_id,
        NEW.group_id,
        'group_invite',
        'Convite para grupo',
        inviter_name || ' convidou você para participar do grupo "' || COALESCE(group_name, 'Grupo sem nome') || '"',
        jsonb_build_object(
            'group_id', NEW.group_id,
            'group_name', COALESCE(group_name, 'Grupo sem nome'),
            'inviter_name', inviter_name,
            'action_required', true
        ),
        NOW() + INTERVAL '7 days'
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar triggers para as tabelas existentes

-- Trigger para despesas (assumindo que a tabela expense tem due_date)
DROP TRIGGER IF EXISTS expense_due_notification_trigger ON expense;
CREATE TRIGGER expense_due_notification_trigger
    AFTER INSERT OR UPDATE OF due_date ON expense
    FOR EACH ROW
    EXECUTE FUNCTION create_expense_due_notification();

-- Trigger para cartões de crédito (assumindo que a tabela credit_cards tem due_date)
DROP TRIGGER IF EXISTS credit_card_due_notification_trigger ON credit_cards;
CREATE TRIGGER credit_card_due_notification_trigger
    AFTER INSERT OR UPDATE OF due_date ON credit_cards
    FOR EACH ROW
    EXECUTE FUNCTION create_credit_card_due_notification();

-- Trigger para financiamentos
DROP TRIGGER IF EXISTS finance_due_notification_trigger ON finance;
CREATE TRIGGER finance_due_notification_trigger
    AFTER INSERT OR UPDATE OF parcelas_quitadas ON finance
    FOR EACH ROW
    EXECUTE FUNCTION create_finance_due_notification();

-- Trigger para convites de grupo
DROP TRIGGER IF EXISTS group_invite_notification_trigger ON group_members;
CREATE TRIGGER group_invite_notification_trigger
    AFTER INSERT ON group_members
    FOR EACH ROW
    EXECUTE FUNCTION create_group_invite_notification();

-- Função para verificar e criar notificações de vencimento diariamente
CREATE OR REPLACE FUNCTION check_daily_due_notifications()
RETURNS INTEGER AS $$
DECLARE
    processed_count INTEGER := 0;
BEGIN
    -- Processar despesas que vencem em 1 ou 3 dias
    INSERT INTO notifications (user_id, group_id, type, title, message, data, expires_at)
    SELECT 
        e.user_id,
        e.group_id,
        'expense_due',
        'Despesa a vencer',
        CASE 
            WHEN (e.due_date::date - CURRENT_DATE) = 1 THEN 
                'A despesa "' || COALESCE(e.description, 'Sem descrição') || '" vence amanhã'
            ELSE 
                'A despesa "' || COALESCE(e.description, 'Sem descrição') || '" vence em ' || (e.due_date::date - CURRENT_DATE) || ' dias'
        END,
        jsonb_build_object(
            'expense_id', e.id,
            'expense_description', COALESCE(e.description, 'Sem descrição'),
            'due_date', e.due_date,
            'amount', e.amount,
            'days_until_due', (e.due_date::date - CURRENT_DATE)
        ),
        e.due_date + INTERVAL '1 day'
    FROM expense e
    WHERE e.due_date IS NOT NULL
    AND (e.due_date::date - CURRENT_DATE) IN (1, 3)
    AND e.paid = false
    AND NOT EXISTS (
        SELECT 1 FROM notifications n
        WHERE n.user_id = e.user_id
        AND n.type = 'expense_due'
        AND n.data->>'expense_id' = e.id::text
        AND n.data->>'due_date' = e.due_date::text
        AND n.created_at::date = CURRENT_DATE
    );
    
    GET DIAGNOSTICS processed_count = ROW_COUNT;
    
    RETURN processed_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comentários
COMMENT ON FUNCTION create_expense_due_notification() IS 'Cria notificações automáticas para vencimento de despesas';
COMMENT ON FUNCTION create_credit_card_due_notification() IS 'Cria notificações automáticas para vencimento de cartões de crédito';
COMMENT ON FUNCTION create_finance_due_notification() IS 'Cria notificações automáticas para vencimento de financiamentos';
COMMENT ON FUNCTION create_group_invite_notification() IS 'Cria notificações automáticas para convites de grupo';
COMMENT ON FUNCTION check_daily_due_notifications() IS 'Função para executar diariamente via cron job para verificar vencimentos';
