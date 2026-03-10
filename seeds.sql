-- ==========================================================
-- SEEDS.SQL - Initial Data Population
-- ==========================================================

-- 1. Create the SYSTEM entity (World Cash)
INSERT INTO entities (id, type, name) 
VALUES ('00000000-0000-0000-0000-000000000001', 'SYSTEM', 'World Cash')
ON CONFLICT DO NOTHING;

-- 2. Seed Bank Brands
INSERT INTO banks (id, name, description, primary_currency, metadata) VALUES
('UB', 'Union Bank', 'Historical and accessible bank, present in every village.', 'EUR', '{}'),
('TF', 'Talos Financial', 'The defense sector bank. Secure, rigorous, and powerful.', 'RUB', '{}'),
('VTT', 'Vanguard Trade & Trust', 'Specialist in international trade and large-scale capital.', 'USD', '{}')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, primary_currency = EXCLUDED.primary_currency, metadata = EXCLUDED.metadata;

-- 3. Seed Products associated with Banks
-- Union Bank Products
INSERT INTO banking_products (id, bank_id, name, interest_rate_percent, max_deposit_limit, withdrawal_fee_percent, transfer_fee_percent, max_accounts_per_entity, allowed_entity_types, can_receive_external_transfers, can_pay_merchants, can_withdraw_cash, minimum_balance)
VALUES 
('UB_CHECKING', 'UB', 'Union Checking Account', 0.00, 2500000, 0.50, 1.00, 2, '["PHYSICAL_PERSON", "MORAL_PERSON"]', TRUE, TRUE, TRUE, 0),
('UB_SAVINGS', 'UB', 'Union Savings Account', 3.00, NULL, 0.00, 5.00, 1, '["PHYSICAL_PERSON"]', FALSE, FALSE, FALSE, 1000)
ON CONFLICT (id) DO UPDATE SET bank_id = EXCLUDED.bank_id, name = EXCLUDED.name, interest_rate_percent = EXCLUDED.interest_rate_percent, transfer_fee_percent = EXCLUDED.transfer_fee_percent;

-- Talos Financial Products
INSERT INTO banking_products (id, bank_id, name, interest_rate_percent, max_deposit_limit, withdrawal_fee_percent, transfer_fee_percent, max_accounts_per_entity, allowed_entity_types, can_receive_external_transfers, can_pay_merchants, can_withdraw_cash, minimum_balance)
VALUES 
('TF_OPERATIVE', 'TF', 'Talos Operative Account', 0.00, 25000000, 0.00, 0.20, 1, '["PHYSICAL_PERSON"]', TRUE, TRUE, TRUE, 500000),
('TF_WAR_CHEST', 'TF', 'Defense Vault', 1.50, NULL, 0.00, 2.00, 1, '["PHYSICAL_PERSON", "MORAL_PERSON"]', TRUE, FALSE, FALSE, 0)
ON CONFLICT (id) DO UPDATE SET bank_id = EXCLUDED.bank_id, name = EXCLUDED.name, interest_rate_percent = EXCLUDED.interest_rate_percent, transfer_fee_percent = EXCLUDED.transfer_fee_percent;

-- Vanguard Trade & Trust Products
INSERT INTO banking_products (id, bank_id, name, interest_rate_percent, max_deposit_limit, withdrawal_fee_percent, transfer_fee_percent, max_accounts_per_entity, allowed_entity_types, can_receive_external_transfers, can_pay_merchants, can_withdraw_cash, minimum_balance)
VALUES 
('VTT_BUSINESS', 'VTT', 'Business Pro Plus', 0.00, NULL, 1.00, 0.50, NULL, '["MORAL_PERSON", "SYSTEM"]', TRUE, TRUE, TRUE, 0)
ON CONFLICT (id) DO UPDATE SET bank_id = EXCLUDED.bank_id, name = EXCLUDED.name, interest_rate_percent = EXCLUDED.interest_rate_percent, transfer_fee_percent = EXCLUDED.transfer_fee_percent;

-- 4. Seed Loan Products
INSERT INTO loan_products (id, name, interest_rate_percent, repayment_interval_days, minimum_amount, maximum_amount, allowed_entity_types)
VALUES 
('PERSONAL_LOAN', 'Union Personal Loan', 8.00, 7, 50000, 500000, '["PHYSICAL_PERSON"]'),
('WAR_CREDIT', 'Talos War Credit', 4.50, 7, 1000000, NULL, '["PHYSICAL_PERSON", "MORAL_PERSON"]'),
('COMMERCIAL_LEASE', 'Vanguard Commercial Lease', 12.00, 30, 5000000, NULL, '["MORAL_PERSON"]')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, interest_rate_percent = EXCLUDED.interest_rate_percent, repayment_interval_days = EXCLUDED.repayment_interval_days;

-- 5. Create the SYSTEM "World Cash" account
-- This account is the source for all cash-to-digital deposits.
INSERT INTO accounts (id, iban, entity_id, product_type_id, balance, currency, status)
VALUES ('00000000-0000-0000-0000-000000000002', 'XX00000000A', '00000000-0000-0000-0000-000000000001', 'UB_CHECKING', 0, 'CRD', 'ACTIVE')
ON CONFLICT DO NOTHING;

-- 6. Default Forex Rates (Reference: CRD)
INSERT INTO forex_rates (base_currency, target_currency, rate) VALUES
('CRD', 'USD', 1.00000000),
('USD', 'CRD', 1.00000000),
('CRD', 'EUR', 0.92000000),
('EUR', 'CRD', 1.08695652),
('CRD', 'RUB', 90.00000000),
('RUB', 'CRD', 0.01111111)
ON CONFLICT DO NOTHING;
