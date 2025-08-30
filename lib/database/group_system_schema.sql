-- Group System Database Schema
-- This script creates the necessary tables and policies for the multi-user group system

-- Create groups table
CREATE TABLE IF NOT EXISTS public.groups (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT DEFAULT '',
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create group_members table
CREATE TABLE IF NOT EXISTS public.group_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    user_email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'inactive')),
    invited_by UUID REFERENCES auth.users(id),
    invited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    joined_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(group_id, user_email)
);

-- Add group_id column to existing tables
ALTER TABLE public.expense ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES public.groups(id);
ALTER TABLE public.finances ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES public.groups(id);
ALTER TABLE public.credit_cards ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES public.groups(id);
ALTER TABLE public.cartao ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES public.groups(id);
ALTER TABLE public.purchases ADD COLUMN IF NOT EXISTS group_id UUID REFERENCES public.groups(id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_groups_owner_id ON public.groups(owner_id);
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON public.group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_email ON public.group_members(user_email);
CREATE INDEX IF NOT EXISTS idx_group_members_status ON public.group_members(status);

CREATE INDEX IF NOT EXISTS idx_expense_group_id ON public.expense(group_id);
CREATE INDEX IF NOT EXISTS idx_finances_group_id ON public.finances(group_id);
CREATE INDEX IF NOT EXISTS idx_credit_cards_group_id ON public.credit_cards(group_id);
CREATE INDEX IF NOT EXISTS idx_cartao_group_id ON public.cartao(group_id);
CREATE INDEX IF NOT EXISTS idx_purchases_group_id ON public.purchases(group_id);

-- Enable Row Level Security
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

-- RLS Policies for groups table
DROP POLICY IF EXISTS "Users can view groups they are members of" ON public.groups;
CREATE POLICY "Users can view groups they are members of" ON public.groups
    FOR SELECT USING (
        id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can create groups" ON public.groups;
CREATE POLICY "Users can create groups" ON public.groups
    FOR INSERT WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "Group owners can update their groups" ON public.groups;
CREATE POLICY "Group owners can update their groups" ON public.groups
    FOR UPDATE USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "Group owners can delete their groups" ON public.groups;
CREATE POLICY "Group owners can delete their groups" ON public.groups
    FOR DELETE USING (owner_id = auth.uid());

-- RLS Policies for group_members table
DROP POLICY IF EXISTS "Users can view group members for their groups" ON public.group_members;
CREATE POLICY "Users can view group members for their groups" ON public.group_members
    FOR SELECT USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
        OR user_email = auth.email()
    );

DROP POLICY IF EXISTS "Group admins can invite users" ON public.group_members;
CREATE POLICY "Group admins can invite users" ON public.group_members
    FOR INSERT WITH CHECK (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() 
            AND status = 'active' 
            AND role IN ('owner', 'admin')
        )
    );

DROP POLICY IF EXISTS "Users can update their own membership" ON public.group_members;
CREATE POLICY "Users can update their own membership" ON public.group_members
    FOR UPDATE USING (
        user_id = auth.uid() 
        OR user_email = auth.email()
        OR group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() 
            AND status = 'active' 
            AND role IN ('owner', 'admin')
        )
    );

DROP POLICY IF EXISTS "Group admins can remove members" ON public.group_members;
CREATE POLICY "Group admins can remove members" ON public.group_members
    FOR DELETE USING (
        user_id = auth.uid()
        OR user_email = auth.email()
        OR group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() 
            AND status = 'active' 
            AND role IN ('owner', 'admin')
        )
    );

-- Update RLS policies for existing tables to include group-based access

-- Expense table policies
DROP POLICY IF EXISTS "Users can view expenses from their groups" ON public.expense;
CREATE POLICY "Users can view expenses from their groups" ON public.expense
    FOR SELECT USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can insert expenses to their groups" ON public.expense;
CREATE POLICY "Users can insert expenses to their groups" ON public.expense
    FOR INSERT WITH CHECK (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can update expenses in their groups" ON public.expense;
CREATE POLICY "Users can update expenses in their groups" ON public.expense
    FOR UPDATE USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can delete expenses from their groups" ON public.expense;
CREATE POLICY "Users can delete expenses from their groups" ON public.expense
    FOR DELETE USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

-- Finances table policies
DROP POLICY IF EXISTS "Users can view finances from their groups" ON public.finances;
CREATE POLICY "Users can view finances from their groups" ON public.finances
    FOR SELECT USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can insert finances to their groups" ON public.finances;
CREATE POLICY "Users can insert finances to their groups" ON public.finances
    FOR INSERT WITH CHECK (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can update finances in their groups" ON public.finances;
CREATE POLICY "Users can update finances in their groups" ON public.finances
    FOR UPDATE USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can delete finances from their groups" ON public.finances;
CREATE POLICY "Users can delete finances from their groups" ON public.finances
    FOR DELETE USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

-- Credit cards table policies
DROP POLICY IF EXISTS "Users can view credit cards from their groups" ON public.credit_cards;
CREATE POLICY "Users can view credit cards from their groups" ON public.credit_cards
    FOR SELECT USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can insert credit cards to their groups" ON public.credit_cards;
CREATE POLICY "Users can insert credit cards to their groups" ON public.credit_cards
    FOR INSERT WITH CHECK (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can update credit cards in their groups" ON public.credit_cards;
CREATE POLICY "Users can update credit cards in their groups" ON public.credit_cards
    FOR UPDATE USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can delete credit cards from their groups" ON public.credit_cards;
CREATE POLICY "Users can delete credit cards from their groups" ON public.credit_cards
    FOR DELETE USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

-- Cartao table policies (installments)
DROP POLICY IF EXISTS "Users can view installments from their groups" ON public.cartao;
CREATE POLICY "Users can view installments from their groups" ON public.cartao
    FOR SELECT USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can insert installments to their groups" ON public.cartao;
CREATE POLICY "Users can insert installments to their groups" ON public.cartao
    FOR INSERT WITH CHECK (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can update installments in their groups" ON public.cartao;
CREATE POLICY "Users can update installments in their groups" ON public.cartao
    FOR UPDATE USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can delete installments from their groups" ON public.cartao;
CREATE POLICY "Users can delete installments from their groups" ON public.cartao
    FOR DELETE USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

-- Purchases table policies
DROP POLICY IF EXISTS "Users can view purchases from their groups" ON public.purchases;
CREATE POLICY "Users can view purchases from their groups" ON public.purchases
    FOR SELECT USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can insert purchases to their groups" ON public.purchases;
CREATE POLICY "Users can insert purchases to their groups" ON public.purchases
    FOR INSERT WITH CHECK (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can update purchases in their groups" ON public.purchases;
CREATE POLICY "Users can update purchases in their groups" ON public.purchases
    FOR UPDATE USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

DROP POLICY IF EXISTS "Users can delete purchases from their groups" ON public.purchases;
CREATE POLICY "Users can delete purchases from their groups" ON public.purchases
    FOR DELETE USING (
        group_id IN (
            SELECT group_id FROM public.group_members 
            WHERE user_id = auth.uid() AND status = 'active'
        )
    );

-- Create function to get member count for groups
CREATE OR REPLACE FUNCTION get_group_member_count(group_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER 
        FROM public.group_members 
        WHERE group_id = group_uuid AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to check if user is group owner
CREATE OR REPLACE FUNCTION is_group_owner(group_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.group_members 
        WHERE group_id = group_uuid 
        AND user_id = user_uuid 
        AND role = 'owner' 
        AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_groups_updated_at ON public.groups;
CREATE TRIGGER update_groups_updated_at
    BEFORE UPDATE ON public.groups
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.groups TO authenticated;
GRANT ALL ON public.group_members TO authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_group_member_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_group_owner(UUID, UUID) TO authenticated;
