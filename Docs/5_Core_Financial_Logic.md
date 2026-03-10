# 5. Capitalism Reforged Business Logic
---

## 🏦 Multi-Bank Ecosystem
The system manages several independent banking brands, each with its own specialization and account currency.

### 1. Union Bank (ID: `UB`)
- **Target**: Civilians and small businesses.
- **Account Currency**: **EUR**.
- **Products**:
    - `UB_CHECKING`: Standard checking account (Fee: 1.00%).
    - `UB_SAVINGS`: Savings book (Interest: 3.00%, No cash withdrawals).

### 2. Talos Financial (ID: `TF`)
- **Target**: Defense sector, mercenaries, and tactical operations.
- **Account Currency**: **RUB**.
- **Products**:
    - `TF_OPERATIVE`: High-liquidity operational account (Fee: 0.20%, Min balance: 500k).
    - `TF_WAR_CHEST`: Defense vault (Interest: 1.50%, No merchant payments).

### 3. Vanguard Trade & Trust (ID: `VTT`)
- **Target**: International, governments, and large capitals.
- **Account Currency**: **USD**.
- **Products**:
    - `VTT_BUSINESS`: Business Pro Plus (Multi-currency, Reduced transfer fees).

## 💰 Loan Types
The middleware supports several types of credits managed via `LoanService`:
- **Personal Loan**: Fixed rate, automatic weekly repayment.
- **War Credit (Talos)**: Intended for equipment purchase, preferential rate.
- **Commercial Lease**: For businesses, high ceilings.

## 💸 Fee Logic (Taxation)
Fees are calculated "On-Top" (above the requested amount).

### For Transfers:
If player A sends **1,000 CRD** to player B with a 1% fee:
1.  **Amount debited** from account A: **1,010 CRD** (1,000 + 10 tax).
2.  **Amount credited** to account B: **1,000 CRD**.

### For Withdrawals:
If a player withdraws **500 CRD** with a 0.5% fee:
1.  **Amount debited** from the account: **502.5 CRD** (500 + 2.5 tax).
2.  **Cash received** by the player: **500 CRD**.

## 💱 Forex Conversion (Pivot Model)
The system uses a fictional reference currency called **CRD** (Credits) as a central pivot. This allows converting any pair of currencies without having to define every combination manually.

### Pivot Operation:
When a transfer takes place between a **RUB** account and an **EUR** account:
1.  The system looks for a direct `RUB -> EUR` rate.
2.  If it doesn't exist, it calculates the rate via the pivot: `(RUB -> CRD) * (CRD -> EUR)`.
3.  **Advantage**: To add a new currency (e.g., GBP), it is enough to define its rate relative to the CRD.

### Precision and Security:
- **Abstraction**: The CRD is an invisible technical account unit. Banks display amounts in their local currency (EUR, USD, RUB).
- **Taxation**: The tax is calculated on the source amount *before* the pivot conversion.
- **SQL Types**: Rates use `NUMERIC(18,8)` to ensure 8 decimal places of precision without loss.

## 👷 Background Workers
The system self-regulates via several background services:
1. **TransactionOutboxWorker**: Processes the asynchronous transaction queue.
2. **InterestCapitalizationWorker**: Calculates and credits interest daily.
3. **SubscriptionWorker**: Manages periodic payments (rents, bills).
4. **LoanRepaymentWorker**: Automated debt collection.

## 🔐 Security & Precision
1.  **All in Integers (`long`)**: Money is stored in **cents**. No `float` type is used.
2.  **Proxies**: Mandataries (`Proxies`) have granular rights and spending ceilings tracked by `initiator_entity_id`.

---
*Next step: [Deployment Guide](6_Project_Deployment.md)*
