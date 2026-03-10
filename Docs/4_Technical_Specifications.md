# 4. DB System Technical Specifications

This document details the technical mechanisms (SQL, Triggers, Constraints) used to implement banking features within the PostgreSQL database.

---

## 1. 🏗️ Ledger Architecture
The `transactions` table uses advanced techniques to ensure the integrity and performance of the General Ledger.

### 1.1 Temporal Partitioning
To maintain consistent performance despite a large volume of data, the `transactions` table is partitioned:
*   **Type**: `RANGE (timestamp)`.
*   **Mechanism**: Use of a `BEFORE INSERT` trigger on the default partition.
*   **Automation**: The `create_transaction_partition_and_insert()` function detects the need for new monthly partitions and creates them dynamically via prepared SQL (`EXECUTE`).

### 1.2 Strict Idempotency
The system technically prevents the double-processing of the same transaction intention:
*   **Partial Unique Index**: `idx_transactions_idempotency` on `(idempotency_key, timestamp)`.
*   **Condition**: `WHERE status != 'FAILED'`. This allows retrying a transaction that previously failed, while blocking any duplication of a successful or in-progress transaction.

## 2. 🛡️ Critical Integrity Controls
The database acts as the last line of defense for business logic.

### 2.1 Overdraft Management
Balance control does not rely on the middleware but on a native SQL constraint:
*   **Constraint**: `CONSTRAINT chk_balance_overdraft CHECK (balance >= overdraft_limit)`.
*   **Advantage**: No application, even malicious or bugged, can force an account below its authorized limit.

### 2.2 Card Security
The `bank_cards` table manages its own security state:
*   **PIN**: Stored as a hash via `pin_hash`.
*   **Attempts**: Atomic increment of the `failed_pin_attempts` field, allowing blocking at the data level independently of the user session.

## 3. 🧩 Object Modeling and Extensibility
The schema uses modern PostgreSQL capabilities to remain flexible.

### 3.1 Use of JSONB
The `JSONB` data type is used extensively to store metadata (`entities`, `banks`, `accounts`) and configurations (`banking_products.allowed_entity_types`).
*   **Performance**: Allows indexing properties within the JSON.
*   **Flexibility**: Allows adding properties without schema migration.

### 3.2 Product Hierarchy
Accounts are not isolated entities; they inherit properties from `banking_products`:
*   **Mapping**: `accounts.product_type_id` → `banking_products.id`.
*   **Logic Injection**: Rates and fees are read dynamically from the product, avoiding data duplication per account.

## 4. 🔄 Automation via Triggers
Metadata updates and temporal synchronization are automated:
*   **Timestamping**: `update_updated_at_column` trigger on almost all tables to ensure a reliable audit trail.
*   **Interest/Debit Calculation**: Although triggered by the Middleware, the structure of the `subscriptions` and `loans` tables (with `last_processed_at` and `next_payment_date`) allows reconstructing the complete state of debts and commitments at any time.

## 5. 🔀 Multi-Currency Exchange Management
The `transactions` table is designed for full financial audit:
*   **Double Entry**: Storage of both source and destination amounts (`destination_amount`).
*   **Exchange Rate**: Capture of the effective `exchange_rate`, ensuring that subsequent financial reports remain accurate even if global exchange rates evolve.

---
*Next step: [Financial Logic & Core Engine](5_Core_Financial_Logic.md)*
