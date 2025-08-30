-- Migration script to support encrypted fields
-- Run this in your Supabase SQL editor

-- Alter expense table to support encrypted amount
ALTER TABLE expense 
ALTER COLUMN amount TYPE TEXT;

-- Alter finances table to support encrypted numeric fields
ALTER TABLE finances 
ALTER COLUMN "valorTotal" TYPE TEXT,
ALTER COLUMN "saldoDevedor" TYPE TEXT,
ALTER COLUMN "valorDesconto" TYPE TEXT,
ALTER COLUMN "valorPago" TYPE TEXT;

-- Alter cartao table to support encrypted valor field
ALTER TABLE cartao 
ALTER COLUMN valor TYPE TEXT;

-- Add comments to document encrypted fields
COMMENT ON COLUMN expense.amount IS 'Encrypted field - stores encrypted numeric values as text';
COMMENT ON COLUMN expense.description IS 'Encrypted field - stores encrypted text values';

COMMENT ON COLUMN finances."valorTotal" IS 'Encrypted field - stores encrypted numeric values as text';
COMMENT ON COLUMN finances."saldoDevedor" IS 'Encrypted field - stores encrypted numeric values as text';
COMMENT ON COLUMN finances."valorDesconto" IS 'Encrypted field - stores encrypted numeric values as text';
COMMENT ON COLUMN finances."valorPago" IS 'Encrypted field - stores encrypted numeric values as text';
COMMENT ON COLUMN finances.tipo IS 'Encrypted field - stores encrypted text values';

COMMENT ON COLUMN cartao."Descricao" IS 'Encrypted field - stores encrypted text values';
COMMENT ON COLUMN cartao.valor IS 'Encrypted field - stores encrypted numeric values as text';
