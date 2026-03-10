# 1. Introduction to the DB System

`Capitalism - DB` is the data foundation of the **Capitalism Reforged** project.

This is where all the system memory resides: accounts, banks, and above all, the history of every transaction.

## Repository Philosophy
This repository is intentionally separated from the rest to ensure security and clarity:
- It contains **data and storage rules**, but not the application code.
- It uses safeguards directly in the database to **prevent calculation errors**.
- It is **turnkey**: once launched via Docker, the system is ready to receive connections from the API.

## Key Components
1. **Database (PostgreSQL)**: The storage engine.
2. **Ledger**: The high-performance transaction table.
3. **Administration (pgAdmin)**: Visual tool for core management.

## Initialization Flow
Every time a new container starts, scripts are executed in this order:
1. `init.sql`: Structure creation.
2. `seeds.sql`: Base data injection.

---
*Next step: [Functional Capabilities](2_Functional_Capabilities.md)*
