# 3. Architecture & Data Model

This document describes how the **Capitalism Reforged** data structure is technically organized to function as a true miniature bank.

---

## 1. Data Model (True Banking IS)

To avoid vulnerabilities (duplications, losses) and ensure perfect traceability, the model must be rigorous and separate **Entities** (who owns) from **Accounts** (where the money is).

### 2.1. Entities (entities)
An entity is a person or organization capable of owning a bank account. *Note: A non-alterable System entity called "World Cash" will exist to track physical cash circulating on the Arma server and balance the money supply.*
- `id`: `UUID` (PRIMARY KEY)
- `type`: `VARCHAR(50)` NOT NULL (e.g., 'PHYSICAL_PERSON', 'MORAL_PERSON', 'SYSTEM')
- `name`: `VARCHAR(255)` NOT NULL (RP name of the player or business name)
- `external_id`: `VARCHAR(255)` UNIQUE NULL (SteamID, Reforger UID, or external business identifier)
- `metadata`: `JSONB` DEFAULT '{}' (High-performance catch-all field for storing free data without modifying the SQL schema: vip_level, last_login)
- `created_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `updated_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `deleted_at`: `TIMESTAMPTZ` NULL (Soft Delete: Financial data is never destroyed, only marked as deleted)

### 2.2. Banking Products (banking_products)
Defines the rules ("Contracts") for different types of accounts (e.g., Checking Account, Savings Account).
- `id`: `VARCHAR(50)` PRIMARY KEY
- `bank_id`: `VARCHAR(50)` NOT NULL REFERENCES banks(id)
- `name`: `VARCHAR(255)` NOT NULL
- `interest_rate_percent`: `NUMERIC(5,2)` NOT NULL DEFAULT 0.00
- `max_deposit_limit`: `BIGINT` NULL
- `withdrawal_fee_percent`: `NUMERIC(5,2)` NOT NULL DEFAULT 0.00
- `transfer_fee_percent`: `NUMERIC(5,2)` NOT NULL DEFAULT 0.00
- `merchant_fee_percent`: `NUMERIC(5,2)` NOT NULL DEFAULT 1.00
- `max_accounts_per_entity`: `INTEGER` NULL
- `allowed_entity_types`: `JSONB` NOT NULL DEFAULT '[]'
- `can_receive_external_transfers`: `BOOLEAN` NOT NULL DEFAULT TRUE
- `can_pay_merchants`: `BOOLEAN` NOT NULL DEFAULT TRUE
- `can_withdraw_cash`: `BOOLEAN` NOT NULL DEFAULT TRUE
- `minimum_balance`: `BIGINT` NOT NULL DEFAULT 0
- `created_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `updated_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()

### 2.3. Bank Accounts (accounts)
An account is always linked to an Entity. *A System account will be dedicated to World Cash.*
- `id`: `UUID` PRIMARY KEY
- `iban`: `VARCHAR(34)` UNIQUE NOT NULL (e.g., "FR12345678A" or "XX00000000A" for World Cash)
- `entity_id`: `UUID` NOT NULL REFERENCES entities(id)
- `product_type_id`: `VARCHAR(50)` NOT NULL REFERENCES banking_products(id)
- `balance`: `BIGINT` NOT NULL DEFAULT 0 CHECK (balance >= overdraft_limit) (Always in whole cents)
- `currency`: `VARCHAR(3)` NOT NULL DEFAULT 'CAP'
- `status`: `VARCHAR(20)` NOT NULL DEFAULT 'ACTIVE' (ACTIVE, CLOSED)
- `can_withdraw`: `BOOLEAN` NOT NULL DEFAULT TRUE (Right for outgoing transfer or payment, can be revoked by Justice)
- `can_deposit`: `BOOLEAN` NOT NULL DEFAULT TRUE (Right for incoming deposit)
- `overdraft_limit`: `BIGINT` NOT NULL DEFAULT 0 (Negative overdraft limit allowed)
- `metadata`: `JSONB` DEFAULT '{}' (On-the-fly account specifics, e.g., daily_withdrawal_limit)
- `created_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `updated_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `deleted_at`: `TIMESTAMPTZ` NULL

### 2.4. Transactions (transactions)
The Ledger records every cent. The table is partitioned by month for performance.
- `id`: `UUID` NOT NULL DEFAULT gen_random_uuid()
- `idempotency_key`: `UUID` NULL (Prevents accidental duplicate transactions)
- `initiator_entity_id`: `UUID` NULL REFERENCES entities(id)
- `timestamp`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW() (Partitioning key)
- `source_account_id`: `UUID` NULL REFERENCES accounts(id)
- `destination_account_id`: `UUID` NULL REFERENCES accounts(id)
- `loan_id`: `UUID` NULL REFERENCES loans(id)
- `amount`: `BIGINT` NOT NULL (Amount in source currency)
- `currency`: `VARCHAR(3)` NOT NULL DEFAULT 'CRD'
- `destination_amount`: `BIGINT` (Amount after forex conversion)
- `destination_currency`: `VARCHAR(3)`
- `exchange_rate`: `NUMERIC(18,8)` NOT NULL DEFAULT 1.0 (Rate applied at time T)
- `tax_amount`: `BIGINT` NOT NULL DEFAULT 0 (Tax amount collected)
- `tax_destination_account_id`: `UUID` NULL REFERENCES accounts(id)
- `category`: `VARCHAR(50)` (SALARY, ITEM_SALE, etc.)
- `source_balance_after`: `BIGINT` (Audit trail of source balance)
- `destination_balance_after`: `BIGINT` (Audit trail of destination balance)
- `type`: `VARCHAR(50)` NOT NULL (TRANSFER, DEPOSIT, WITHDRAW, etc.)
- `status`: `VARCHAR(20)` NOT NULL DEFAULT 'PENDING'
- `reference`: `TEXT` NULL
- `metadata`: `JSONB` DEFAULT '{}'
- `created_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `updated_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()

### 2.5. Loans (loans)
Manages credits granted by the bank or between players/businesses.
- `id`: `UUID` PRIMARY KEY
- `borrower_entity_id`: `UUID` NOT NULL REFERENCES entities(id)
- `total_amount`: `BIGINT` NOT NULL CHECK (total_amount > 0)
- `remaining_amount`: `BIGINT` NOT NULL CHECK (remaining_amount >= 0)
- `interest_rate_percent`: `NUMERIC(5,2)` NOT NULL
- `next_payment_date`: `TIMESTAMPTZ` NULL
- `status`: `VARCHAR(20)` NOT NULL DEFAULT 'ACTIVE'
- `created_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()

### 2.6. Permits and Licenses (licenses)
Purchase rights linked to the economy (e.g., Right to buy heavy weapons).
- `id`: `UUID` PRIMARY KEY
- `entity_id`: `UUID` NOT NULL REFERENCES entities(id)
- `license_type`: `VARCHAR(100)` NOT NULL (e.g., WEAPON_LICENSE)
- `acquired_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `expires_at`: `TIMESTAMPTZ` NULL

### 2.7. Exchange Rates (forex_rates)
Manages a multi-currency environment if needed.
- `base_currency`: `VARCHAR(3)` NOT NULL
- `target_currency`: `VARCHAR(3)` NOT NULL
- `rate`: `NUMERIC(10,4)` NOT NULL CHECK (rate > 0)
- `updated_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
*(Note: Composite PRIMARY KEY on base_currency, target_currency)*
*(Examples:
    - `forex_rates`: `base_currency`=CRD, `target_currency`=USD, rate=1.0 (Parity)
    - `forex_rates`: `base_currency`=CRD, `target_currency`=RUB, rate=80.0 (1 CRD = 80 RUB)
    - `forex_rates`: `base_currency`=USD, `target_currency`=CRD, rate=1.0
)*

**Note**: Account balances (`balance`) are `BIGINT` representing **cents** (e.g., 1000 = 10.00 CRD).

### 2.8. Joint Accounts and Co-owners (account_owners)
Allows multiple physical players to share full ownership of an account.
- `account_id`: `UUID` NOT NULL REFERENCES accounts(id)
- `entity_id`: `UUID` NOT NULL REFERENCES entities(id)
- `role`: `VARCHAR(50)` NOT NULL DEFAULT 'CO_OWNER'
*(Note: Composite PRIMARY KEY on account_id, entity_id)*

### 2.9. Proxies and Mandates (account_proxies)
Gives the right to spend money from an account (e.g., business) to another player, with limits.
- `id`: `UUID` PRIMARY KEY
- `account_id`: `UUID` NOT NULL REFERENCES accounts(id)
- `proxy_entity_id`: `UUID` NOT NULL REFERENCES entities(id)
- `daily_spending_limit`: `BIGINT` NULL (Daily spending limit)
- `can_transfer_money`: `BOOLEAN` NOT NULL DEFAULT FALSE (Right to transfer money from the business account to their own account, dangerous!)
- `can_buy_from_merchants`: `BOOLEAN` NOT NULL DEFAULT TRUE (Right to buy items for the faction)
- `can_withdraw_cash`: `BOOLEAN` NOT NULL DEFAULT FALSE (Right to go to the ATM and withdraw business cash)
- `created_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `expires_at`: `TIMESTAMPTZ` NULL (Proxy end date)

### 2.10. Automated Debits (subscriptions)
Recurring bills (rents, phones, taxes).
- `id`: `UUID` PRIMARY KEY
- `source_account_id`: `UUID` NOT NULL REFERENCES accounts(id)
- `destination_account_id`: `UUID` NOT NULL REFERENCES accounts(id)
- `amount`: `BIGINT` NOT NULL CHECK (amount > 0)
- `frequency_hours`: `INTEGER` NOT NULL CHECK (frequency_hours > 0)
- `last_processed_at`: `TIMESTAMPTZ` NULL
- `status`: `VARCHAR(20)` NOT NULL DEFAULT 'ACTIVE'
- `created_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()

### 2.11. Bank Cards (bank_cards)
Physical object in game, linked to an account to authorize payments.
- `id`: `UUID` PRIMARY KEY (can correspond to an item ID in the Arma inventory)
- `account_id`: `UUID` NOT NULL REFERENCES accounts(id)
- `pin_hash`: `VARCHAR(255)` NOT NULL (Hash of the 4-digit PIN code)
- `failed_pin_attempts`: `INTEGER` NOT NULL DEFAULT 0 (Security: blocks the card after 3 errors)
- `status`: `VARCHAR(20)` NOT NULL DEFAULT 'ACTIVE' (ACTIVE, BLOCKED, EXPIRED)
- `daily_payment_limit`: `BIGINT` NULL (Physical payment ceiling independent of the account)
- `created_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `expires_at`: `TIMESTAMPTZ` NULL
- `deleted_at`: `TIMESTAMPTZ` NULL

### 2.12. Transaction Queue (transaction_queue) - *Anti-Crash Protection*
Ensures that no transaction initiated by the game is lost if the Middleware crashes before processing. Implements the "Outbox" or "Job Queue" pattern.
- `id`: `UUID` PRIMARY KEY
- `payload`: `JSONB` NOT NULL (Raw content of the request to process)
- `session_id`: `VARCHAR(255)` NULL (Session tracking)
- `status`: `VARCHAR(20)` NOT NULL DEFAULT 'PENDING'
- `error_message`: `TEXT` NULL
- `retry_count`: `INTEGER` NOT NULL DEFAULT 0
- `created_at`: `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `scheduled_at`: `TIMESTAMPTZ`
- `processing_started_at`: `TIMESTAMPTZ`
- `processed_at`: `TIMESTAMPTZ` NULL

**Processing (Middleware):**
This table is monitored by a Middleware background service (`TransactionOutboxWorker`). It retrieves tasks via secure polling (`SKIP LOCKED`) to process them sequentially without blocking the database. This allows supporting player disconnections and load spikes without data loss.

### 2.13. Relational Schema and Cardinalities (ERD)
To understand how these tables interact via their Foreign Key constraints, here is the exact map of their cardinal relations:

#### 1:N Relations (One-to-Many)
- **`entities` (1) ─── `accounts` (N)**: A player or business can own zero to several bank accounts, but a bank account belongs (primarily) to a single entity.
- **`banking_products` (1) ─── `accounts` (N)**: A banking product (e.g., "Savings Account") applies to an infinite number of accounts, but an account obeys one and only one product contract.
- **`accounts` (1) ─── `transactions` (N)** *(as source account)*: An account can be the origin of multiple outgoing transfers.
- **`accounts` (1) ─── `transactions` (N)** *(as destination account)*: An account can receive multiple incoming transfers.
- **`entities` (1) ─── `licenses` (N)**: A player can hold several licenses (Weapons, Helicopter, Business Owner).
- **`entities` (1) ─── `loans` (N)**: A player/business can take out several loans at the same time.
- **`loans` (1) ─── `transactions` (N)**: A single loan will be the subject of multiple repayment transactions (installments).
- **`accounts` (1) ─── `bank_cards` (N)**: The same main checking account can have several bank cards issued (e.g., if the player owns a Business account, they can create 3 cards for their 3 employees pointing to this same account).

#### N:N Relations (Many-to-Many)
*These relations require a Junction Table in a SQL architecture.*
- **`entities` (N) ─── [ `account_owners` ] ─── `accounts` (N)**: (Joint Accounts). 
  - *Reading:* An account can belong jointly to several entities (e.g., a couple of players). 
  - *Inverse reading:* An entity can be a co-holder of several joint accounts.
- **`entities` (N) ─── [ `account_proxies` ] ─── `accounts` (N)**: (Proxies).
  - *Reading:* A business account can have its management delegated to several employees.
  - *Inverse reading:* A player can have a proxy for several different businesses.
- **`accounts` (N) ─── [ `subscriptions` ] ─── `accounts` (N)**: (Automatic Debits).
  - *Reading:* Account A can issue several debits (Netflix, Rent, Fine).
  - *Inverse reading:* Account B (the Dealership) can receive hundreds of automatic debits from hundreds of customer accounts.

#### Simplified Visual Representation (Mermaid Line)
`(entities)` ---> `(accounts)` ---> `(transactions)`
`|-->(licenses)`  `|-->(bank_cards)`     `|-->(transaction_queue)`
`|-->(loans)`     `|-->(subscriptions)`

---

## 3. Chosen Technologies
- **Backend / DB:** **PostgreSQL** (Perfect ACID robustness, optional replication for High Availability).
- **Middleware:** **C# (.NET 8+)** (High performance, mature ASP.NET Core ecosystem, native Linux/Docker multi-platform, high proximity to Arma Reforger's EnfusionScript).
- **Communication Arma -> Middleware:** REST API (`RestApi` in the Enfusion Engine).

---
*Next step: [Technical Specifications](4_Technical_Specifications.md)*
