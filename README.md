# 🏦 Capitalism - DB

**Capitalism - DB** is the central data foundation for the **Capitalism Reforged** project.

It is a robust database designed to reliably store all financial and economic information of the system. Although initially created for the game, it uses real accounting principles to ensure that every cent is tracked.

It serves as the **source of truth** for the ecosystem. This is where storage rules, account structures, and bank parameters are defined.

## 🎯 Vision and Objectives
The data layer was designed as a digital vault:
*   **Openness**: Can be used with any program (C#, Python, Node.js) or game.
*   **Financial Security**: Uses strict mathematical rules within the database to prevent calculation errors or impossible negative balances.
*   **Performance**: Production-ready, capable of handling millions of transactions without slowdowns.

## ✨ Key Features
*   **Multi-Currency Ledger**: Native support for Foreign Exchange (Forex) and automatic taxation.
*   **Abstract Entity Structure**: Unified management of Individuals, Businesses, Factions, and States.
*   **Complete Electronic Money**: Management of bank cards (PIN, limits, lifecycles).
*   **Loan & Interest System**: Engine for calculating and tracking debts and returns.
*   **Delegations & Proxies**: Granular controls for shared access (faction/business accounts).

## 📂 Project Structure
- `init.sql`: Technical schema definition (Tables, Indexes, Triggers).
- `seeds.sql`: Default business configuration (Banks, Offers, Rates).
- `docker-compose.yml`: Ready-to-use orchestration (PostgreSQL 17 + pgAdmin).
- `docs/`: In-depth documentation.
  - [1. Introduction](docs/1_Introduction.md)
  - [2. Functional Capabilities](docs/2_Functional_Capabilities.md)
  - [3. Data Model & Architecture](docs/3_Data_Model_Architecture.md)
  - [4. Technical Specifications](docs/4_Technical_Specifications.md)
  - [5. Core Financial Logic](docs/5_Core_Financial_Logic.md)
  - [6. Deployment Guide](docs/6_Project_Deployment.md)

## 🚀 Quick Start

### 1. Prerequisites
*   Docker & Docker Compose.
*   Copy `.env.example` to `.env` and configure your secrets.

### 2. Launch
```bash
docker-compose up -d
```
This will start:
*   **PostgreSQL** on port `5432` (default).
*   **pgAdmin** on port `5050` (default).

## 🛡️ License
This project is under a **Proprietary License (All rights reserved)**.

See the [LICENSE](LICENSE) file for more details.

Any modification or redistribution is prohibited without authorization.