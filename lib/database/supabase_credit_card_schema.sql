-- =====================================================
-- ESQUEMA SUPABASE PARA CONTROLE DE CARTÃO DE CRÉDITO
-- =====================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABELA: credit_cards (Cartões de Crédito)
-- =====================================================
CREATE TABLE credit_cards (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Informações básicas do cartão
    card_name VARCHAR(100) NOT NULL,
    card_number_masked VARCHAR(20), -- Ex: "**** **** **** 1234"
    bank_name VARCHAR(100),
    card_type VARCHAR(20) DEFAULT 'credit', -- credit, debit, multiple
    
    -- Limites e valores
    credit_limit DECIMAL(15,2) NOT NULL DEFAULT 0,
    available_limit DECIMAL(15,2) NOT NULL DEFAULT 0,
    current_balance DECIMAL(15,2) NOT NULL DEFAULT 0,
    
    -- Datas importantes
    closing_day INTEGER CHECK (closing_day >= 1 AND closing_day <= 31),
    due_day INTEGER CHECK (due_day >= 1 AND due_day <= 31),
    
    -- Configurações
    is_active BOOLEAN DEFAULT true,
    card_color VARCHAR(7) DEFAULT '#2196F3', -- Cor hex para UI
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_limits CHECK (available_limit <= credit_limit)
);

-- =====================================================
-- TABELA: purchases (Compras)
-- =====================================================
CREATE TABLE purchases (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    credit_card_id UUID REFERENCES credit_cards(id) ON DELETE CASCADE,
    
    -- Informações da compra
    description VARCHAR(255) NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL CHECK (total_amount > 0),
    installments_count INTEGER NOT NULL DEFAULT 1 CHECK (installments_count > 0),
    installment_amount DECIMAL(15,2) NOT NULL CHECK (installment_amount > 0),
    
    -- Categoria e localização
    category VARCHAR(100),
    merchant_name VARCHAR(150),
    location VARCHAR(200),
    
    -- Datas
    purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
    first_installment_date DATE NOT NULL,
    
    -- Status
    status VARCHAR(20) DEFAULT 'active', -- active, cancelled, completed
    
    -- Observações
    notes TEXT,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_installment_amount CHECK (
        installment_amount * installments_count = total_amount
    )
);

-- =====================================================
-- TABELA: installments (Parcelas)
-- =====================================================
CREATE TABLE installments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    purchase_id UUID REFERENCES purchases(id) ON DELETE CASCADE,
    credit_card_id UUID REFERENCES credit_cards(id) ON DELETE CASCADE,
    
    -- Informações da parcela
    installment_number INTEGER NOT NULL CHECK (installment_number > 0),
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    original_amount DECIMAL(15,2) NOT NULL CHECK (original_amount > 0),
    
    -- Datas
    due_date DATE NOT NULL,
    payment_date DATE,
    
    -- Status de pagamento
    status VARCHAR(20) DEFAULT 'pending', -- pending, paid, overdue, cancelled
    
    -- Informações de pagamento
    payment_amount DECIMAL(15,2),
    payment_method VARCHAR(50), -- bank_transfer, pix, cash, etc
    
    -- Juros e multas (se aplicável)
    interest_amount DECIMAL(15,2) DEFAULT 0,
    late_fee DECIMAL(15,2) DEFAULT 0,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    
    -- Observações
    payment_notes TEXT,
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(purchase_id, installment_number)
);

-- =====================================================
-- TABELA: credit_card_statements (Faturas do Cartão)
-- =====================================================
CREATE TABLE credit_card_statements (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    credit_card_id UUID REFERENCES credit_cards(id) ON DELETE CASCADE,
    
    -- Período da fatura
    statement_date DATE NOT NULL,
    due_date DATE NOT NULL,
    closing_date DATE NOT NULL,
    
    -- Valores da fatura
    previous_balance DECIMAL(15,2) DEFAULT 0,
    current_charges DECIMAL(15,2) DEFAULT 0,
    payments_credits DECIMAL(15,2) DEFAULT 0,
    interest_charges DECIMAL(15,2) DEFAULT 0,
    fees DECIMAL(15,2) DEFAULT 0,
    total_amount DECIMAL(15,2) NOT NULL,
    minimum_payment DECIMAL(15,2) NOT NULL,
    
    -- Status
    status VARCHAR(20) DEFAULT 'open', -- open, paid, overdue, partial
    payment_date DATE,
    payment_amount DECIMAL(15,2),
    
    -- Metadados
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(credit_card_id, statement_date)
);

-- =====================================================
-- TABELA: expense_categories (Categorias de Gastos)
-- =====================================================
CREATE TABLE expense_categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    name VARCHAR(100) NOT NULL,
    description TEXT,
    color VARCHAR(7) DEFAULT '#757575',
    icon VARCHAR(50) DEFAULT 'category',
    
    -- Hierarquia (categoria pai)
    parent_category_id UUID REFERENCES expense_categories(id),
    
    -- Configurações
    is_active BOOLEAN DEFAULT true,
    budget_limit DECIMAL(15,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, name)
);

-- =====================================================
-- TABELA: payment_alerts (Alertas de Pagamento)
-- =====================================================
CREATE TABLE payment_alerts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    credit_card_id UUID REFERENCES credit_cards(id) ON DELETE CASCADE,
    installment_id UUID REFERENCES installments(id) ON DELETE CASCADE,
    
    alert_type VARCHAR(30) NOT NULL, -- due_date, overdue, statement_ready
    alert_date DATE NOT NULL,
    days_before INTEGER DEFAULT 3,
    
    -- Status
    is_sent BOOLEAN DEFAULT false,
    sent_at TIMESTAMP WITH TIME ZONE,
    
    -- Configurações
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- ÍNDICES PARA PERFORMANCE
-- =====================================================

-- Índices para credit_cards
CREATE INDEX idx_credit_cards_user_id ON credit_cards(user_id);
CREATE INDEX idx_credit_cards_active ON credit_cards(user_id, is_active);

-- Índices para purchases
CREATE INDEX idx_purchases_user_id ON purchases(user_id);
CREATE INDEX idx_purchases_card_id ON purchases(credit_card_id);
CREATE INDEX idx_purchases_date ON purchases(purchase_date);
CREATE INDEX idx_purchases_status ON purchases(status);

-- Índices para installments
CREATE INDEX idx_installments_user_id ON installments(user_id);
CREATE INDEX idx_installments_purchase_id ON installments(purchase_id);
CREATE INDEX idx_installments_card_id ON installments(credit_card_id);
CREATE INDEX idx_installments_due_date ON installments(due_date);
CREATE INDEX idx_installments_status ON installments(status);
CREATE INDEX idx_installments_pending ON installments(user_id, status) WHERE status = 'pending';

-- Índices para statements
CREATE INDEX idx_statements_card_id ON credit_card_statements(credit_card_id);
CREATE INDEX idx_statements_due_date ON credit_card_statements(due_date);
CREATE INDEX idx_statements_status ON credit_card_statements(status);

-- Índices para categories
CREATE INDEX idx_categories_user_id ON expense_categories(user_id);
CREATE INDEX idx_categories_parent ON expense_categories(parent_category_id);

-- Índices para alerts
CREATE INDEX idx_alerts_user_id ON payment_alerts(user_id);
CREATE INDEX idx_alerts_date ON payment_alerts(alert_date);
CREATE INDEX idx_alerts_pending ON payment_alerts(is_sent, is_active) WHERE is_sent = false AND is_active = true;

-- =====================================================
-- RLS (ROW LEVEL SECURITY) POLICIES
-- =====================================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE credit_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_card_statements ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_alerts ENABLE ROW LEVEL SECURITY;

-- Políticas para credit_cards
CREATE POLICY "Users can view own credit cards" ON credit_cards
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own credit cards" ON credit_cards
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own credit cards" ON credit_cards
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own credit cards" ON credit_cards
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas para purchases
CREATE POLICY "Users can view own purchases" ON purchases
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own purchases" ON purchases
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own purchases" ON purchases
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own purchases" ON purchases
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas para installments
CREATE POLICY "Users can view own installments" ON installments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own installments" ON installments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own installments" ON installments
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own installments" ON installments
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas para statements
CREATE POLICY "Users can view own statements" ON credit_card_statements
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own statements" ON credit_card_statements
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own statements" ON credit_card_statements
    FOR UPDATE USING (auth.uid() = user_id);

-- Políticas para categories
CREATE POLICY "Users can view own categories" ON expense_categories
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own categories" ON expense_categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own categories" ON expense_categories
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own categories" ON expense_categories
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas para alerts
CREATE POLICY "Users can view own alerts" ON payment_alerts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own alerts" ON payment_alerts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own alerts" ON payment_alerts
    FOR UPDATE USING (auth.uid() = user_id);

-- =====================================================
-- TRIGGERS PARA ATUALIZAÇÃO AUTOMÁTICA
-- =====================================================

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para updated_at
CREATE TRIGGER update_credit_cards_updated_at BEFORE UPDATE ON credit_cards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_purchases_updated_at BEFORE UPDATE ON purchases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_installments_updated_at BEFORE UPDATE ON installments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_statements_updated_at BEFORE UPDATE ON credit_card_statements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON expense_categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();