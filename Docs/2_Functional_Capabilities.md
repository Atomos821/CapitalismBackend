# 2. Functional Capabilities of Capitalism Reforged

This document presents what the **Capitalism Reforged** system can concretely do (accounts, loans, cards, etc.), independent of the code or the game.

---

## 1. 👥 Economic Actors Management
The system is based on an abstract entity model allowing for different profiles:
*   **Individuals**: Personal accounts for players.
*   **Organizations**: Businesses, unions, factions, or government groups.
*   **System Services**: Regulatory entities or central banks.
*   **History and Traceability**: Each actor has a complete lifecycle, allowing accounting archives to be kept even after an organization is dissolved or an individual leaves.

## 2. 🏛️ Multi-Brand Banking System
The structure allows for the coexistence of several banking institutions within the same economy:
*   **Unique Identity**: Each bank can have its own name, description, and reference currency.
*   **Visual Configuration**: The configuration allows for adapting the appearance of interfaces (colors, logos) according to the chosen establishment.

## 3. 💳 Banking Product Catalog
The system allows for modeling a wide range of dynamically configurable financial products.

### 3.1 Deposit Accounts
The catalog allows for the creation of various accounts (Checking, Savings, Business) defined by:
*   **Yield**: Interest rates on balances.
*   **Accessibility**: Variable permissions for withdrawals, deposits, and payments.
*   **Pricing**: Customizable withdrawal and transfer fees per product.
*   **Balance Constraints**: Mandatory minimum amounts or deposit ceilings.

### 3.2 Financing Solutions (Loans)
The base natively supports credit products with:
*   Specific interest rates.
*   Flexible repayment schedules (weekly, monthly, etc.).
*   Amount limits adapted to each type of clientele.

## 4. 🔒 Protection and Risk Management
Control mechanisms are natively integrated at the data level:
*   **Overdraft Management**: Configurable negative tolerance limit per account, technically preventing any unauthorized overdraft.
*   **Security Locking**: Ability to suspend account operations (freeze funds) for security reasons.

## 5. 🤝 Shared Ownership and Delegation
The model allows for complex management of access to funds:
*   **Joint Accounts**: Several individuals or managers can be co-owners of the same account.
*   **Mandates (Proxies)**: A system for delegating access to an account with precise restrictions (daily spending limits, prohibition of cash withdrawals).

## 6. 🏧 Electronic Payment Network (Bank Cards)
The system manages virtual or physical payment cards:
*   **Securing**: PIN code protection and automatic blocking after several errors.
*   **Limit Tracking**: Daily payment limits independent of the available balance.

## 7. ⏳ Workflow Automation (Direct Debits and Engagements)
The foundation allows for scheduling recurring or deferred transactions:
*   **Recurrence**: Salaries, rents, subscriptions, or taxes automatically deducted at regular intervals.
*   **Scheduling**: Planned transfer orders for future execution.

## 8. 💱 Exchange and Taxation
The transaction ledger natively integrates advanced management concepts:
*   **Taxation at Source**: Automatic calculation and redirection of taxes to administration accounts.
*   **Exchange Management**: Support for multi-currency transfers with recording of the rate applied at the time of the operation.

---
*Next step: [Architecture & Data Model](3_Data_Model_Architecture.md)*
