-- ==========================================================
-- CAPITALISM-DATACORE - INITIAL SCHEMA DEFINITION
-- Description: Core tables, triggers, and functions for the banking system.
-- ==========================================================

-- 0. Utilities
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- 0.1 Partition Automation
CREATE OR REPLACE FUNCTION create_transaction_partition_and_insert()
RETURNS TRIGGER AS $$
DECLARE
    partition_date TEXT;
    partition_name TEXT;
    start_date TEXT;
    end_date TEXT;
BEGIN
    -- Determine partition name (e.g., transactions_y2026m03)
    partition_name := 'transactions_y' || to_char(NEW.timestamp, 'YYYY') || 'm' || to_char(NEW.timestamp, 'MM');
    start_date := to_char(date_trunc('month', NEW.timestamp), 'YYYY-MM-DD');
    end_date := to_char(date_trunc('month', NEW.timestamp) + interval '1 month', 'YYYY-MM-DD');

    -- Create partition for CURRENT record IF NOT EXISTS
    BEGIN
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF transactions FOR VALUES FROM (%L) TO (%L)', 
            partition_name, start_date, end_date);
    EXCEPTION WHEN duplicate_table THEN
        NULL;
    END;

    -- PROACTIVE: Create partition for NEXT month as well to avoid trigger overhead for the first tx of next month
    DECLARE
        next_month TIMESTAMPTZ;
        next_partition_name TEXT;
        next_start_date TEXT;
        next_end_date TEXT;
    BEGIN
        next_month := date_trunc('month', NEW.timestamp) + interval '1 month';
        next_partition_name := 'transactions_y' || to_char(next_month, 'YYYY') || 'm' || to_char(next_month, 'MM');
        next_start_date := to_char(next_month, 'YYYY-MM-DD');
        next_end_date := to_char(next_month + interval '1 month', 'YYYY-MM-DD');
        
        EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF transactions FOR VALUES FROM (%L) TO (%L)', 
            next_partition_name, next_start_date, next_end_date);
    EXCEPTION WHEN duplicate_table THEN
        NULL;
    END;

    -- Insert into the correct partition
    EXECUTE format('INSERT INTO %I SELECT ($1).*', partition_name) USING NEW;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 1. Entities (Physical Persons, Moral Persons, System)
CREATE TABLE IF NOT EXISTS entities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(50) NOT NULL, -- 'PHYSICAL_PERSON', 'MORAL_PERSON', 'SYSTEM'
    name VARCHAR(255) NOT NULL,
    external_id VARCHAR(255) UNIQUE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TRIGGER update_entities_updated_at BEFORE UPDATE ON entities FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- 2. Banks (Branding & Identity)
CREATE TABLE IF NOT EXISTS banks (
    id VARCHAR(50) PRIMARY KEY, -- 'UP', 'AF', 'VTT'
    name VARCHAR(255) NOT NULL,
    description TEXT,
    primary_currency VARCHAR(3) NOT NULL DEFAULT 'CRD',
    metadata JSONB DEFAULT '{}', -- colors, logo_ui_ref
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Banking Products
CREATE TABLE IF NOT EXISTS banking_products (
    id VARCHAR(50) PRIMARY KEY,
    bank_id VARCHAR(50) NOT NULL REFERENCES banks(id),
    name VARCHAR(255) NOT NULL,
    interest_rate_percent NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    max_deposit_limit BIGINT,
    withdrawal_fee_percent NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    transfer_fee_percent NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    max_accounts_per_entity INTEGER,
    allowed_entity_types JSONB NOT NULL DEFAULT '[]',
    can_receive_external_transfers BOOLEAN NOT NULL DEFAULT TRUE,
    can_pay_merchants BOOLEAN NOT NULL DEFAULT TRUE,
    merchant_fee_percent NUMERIC(5,2) NOT NULL DEFAULT 1.00,
    can_withdraw_cash BOOLEAN NOT NULL DEFAULT TRUE,
    minimum_balance BIGINT NOT NULL DEFAULT 0
);

-- 4. Loan Products
CREATE TABLE IF NOT EXISTS loan_products (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    interest_rate_percent NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    repayment_interval_days INTEGER NOT NULL DEFAULT 7, -- Default to weekly
    minimum_amount BIGINT NOT NULL DEFAULT 0,
    maximum_amount BIGINT,
    allowed_entity_types JSONB NOT NULL DEFAULT '[]'
);

-- 3. Accounts
CREATE TABLE IF NOT EXISTS accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    iban VARCHAR(34) UNIQUE NOT NULL,
    entity_id UUID NOT NULL REFERENCES entities(id),
    product_type_id VARCHAR(50) NOT NULL REFERENCES banking_products(id),
    balance BIGINT NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL DEFAULT 'CAP',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- 'ACTIVE', 'CLOSED'
    can_withdraw BOOLEAN NOT NULL DEFAULT TRUE,
    can_deposit BOOLEAN NOT NULL DEFAULT TRUE,
    overdraft_limit BIGINT NOT NULL DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT chk_balance_overdraft CHECK (balance >= overdraft_limit)
);

CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- 5. Loans
CREATE TABLE IF NOT EXISTS loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    borrower_entity_id UUID NOT NULL REFERENCES entities(id),
    loan_product_id VARCHAR(50) REFERENCES loan_products(id),
    total_amount BIGINT NOT NULL CHECK (total_amount > 0),
    remaining_amount BIGINT NOT NULL CHECK (remaining_amount >= 0),
    interest_rate_percent NUMERIC(5,2) NOT NULL,
    next_payment_date TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_loans_updated_at BEFORE UPDATE ON loans FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- 5. Transactions (The core ledger)
CREATE TABLE IF NOT EXISTS transactions (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    idempotency_key UUID, -- UNIQUE constraint replaced by partial index below
    initiator_entity_id UUID REFERENCES entities(id),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    source_account_id UUID REFERENCES accounts(id),
    destination_account_id UUID REFERENCES accounts(id),
    loan_id UUID REFERENCES loans(id),
    amount BIGINT NOT NULL CHECK (amount > 0), -- Amount in source currency
    currency VARCHAR(3) NOT NULL DEFAULT 'CRD',
    destination_amount BIGINT, -- Amount in target currency
    destination_currency VARCHAR(3),
    exchange_rate NUMERIC(18,8) NOT NULL DEFAULT 1.0,
    tax_amount BIGINT NOT NULL DEFAULT 0,
    tax_destination_account_id UUID REFERENCES accounts(id),
    category VARCHAR(50), -- 'SALARY', 'ITEM_SALE', etc.
    source_balance_after BIGINT,
    destination_balance_after BIGINT,
    type VARCHAR(50) NOT NULL, -- 'TRANSFER', 'DEPOSIT', 'WITHDRAW', 'PAYCHECK', 'PURCHASE', 'FEE', 'INTEREST'
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'COMPLETED', 'FAILED'
    reference TEXT,
    metadata JSONB DEFAULT '{}',
    PRIMARY KEY (id, timestamp)
) PARTITION BY RANGE (timestamp);

-- Default partition for safety (automated partitions will be created by this table's trigger)
CREATE TABLE IF NOT EXISTS transactions_default PARTITION OF transactions DEFAULT;

-- Trigger to automate partition creation when a row hits the default partition
CREATE TRIGGER trg_transactions_default_insert
BEFORE INSERT ON transactions_default
FOR EACH ROW EXECUTE PROCEDURE create_transaction_partition_and_insert();

-- Index for idempotency: allow reusing a key if the previous attempt FAILED
-- Note: On partitioned tables, unique indexes must include the partition key
CREATE UNIQUE INDEX idx_transactions_idempotency 
ON transactions (idempotency_key, timestamp) 
WHERE idempotency_key IS NOT NULL AND status != 'FAILED';

-- Performance index for soft-deletes
CREATE INDEX idx_accounts_deleted_at ON accounts (deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_entities_deleted_at ON entities (deleted_at) WHERE deleted_at IS NULL;

-- 6. Licenses
CREATE TABLE IF NOT EXISTS licenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id UUID NOT NULL REFERENCES entities(id),
    license_type VARCHAR(100) NOT NULL,
    acquired_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- 7. Forex Rates
CREATE TABLE IF NOT EXISTS forex_rates (
    base_currency VARCHAR(3) NOT NULL,
    target_currency VARCHAR(3) NOT NULL,
    rate NUMERIC(18,8) NOT NULL CHECK (rate > 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (base_currency, target_currency)
);

CREATE TRIGGER update_forex_rates_updated_at BEFORE UPDATE ON forex_rates FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- 8. Account Owners (Joint Accounts / Many-to-Many)
CREATE TABLE IF NOT EXISTS account_owners (
    account_id UUID NOT NULL REFERENCES accounts(id),
    entity_id UUID NOT NULL REFERENCES entities(id),
    role VARCHAR(50) NOT NULL DEFAULT 'CO_OWNER',
    PRIMARY KEY (account_id, entity_id)
);

-- 9. Account Proxies
CREATE TABLE IF NOT EXISTS account_proxies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id),
    proxy_entity_id UUID NOT NULL REFERENCES entities(id),
    daily_spending_limit BIGINT,
    can_transfer_money BOOLEAN NOT NULL DEFAULT FALSE,
    can_buy_from_merchants BOOLEAN NOT NULL DEFAULT TRUE,
    can_withdraw_cash BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- 10. Subscriptions (Direct Debits)
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_account_id UUID NOT NULL REFERENCES accounts(id),
    destination_account_id UUID NOT NULL REFERENCES accounts(id),
    amount BIGINT NOT NULL CHECK (amount > 0),
    frequency_hours INTEGER NOT NULL CHECK (frequency_hours > 0),
    description VARCHAR(255),
    category VARCHAR(50) NOT NULL DEFAULT 'SUBSCRIPTION', -- 'SUBSCRIPTION', 'SALARY', 'RENT', 'TAX'
    last_processed_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. Bank Cards
CREATE TABLE IF NOT EXISTS bank_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id),
    pin_hash VARCHAR(255) NOT NULL,
    failed_pin_attempts INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- 'ACTIVE', 'BLOCKED', 'EXPIRED'
    daily_payment_limit BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);

-- 12. Transaction Queue (Outbox Pattern)
CREATE TABLE IF NOT EXISTS transaction_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payload JSONB NOT NULL,
    session_id VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'PROCESSING', 'COMPLETED', 'FAILED'
    error_message TEXT,
    retry_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    scheduled_at TIMESTAMPTZ,
    processing_started_at TIMESTAMPTZ,
    processed_at TIMESTAMPTZ
);
