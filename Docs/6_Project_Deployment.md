# 6. Deployment Guide

This guide explains how to deploy the **Capitalism - DB** foundation using Docker.

## 📋 Prerequisites
- **Docker** & **Docker Compose** installed.
- Port `5432` (Database) and `5050` (pgAdmin - optional) available on the host.

## 🔨 Configuration
1.  Copy `.env.example` to `.env`.
2.  Update the credentials (`POSTGRES_USER`, `POSTGRES_PASSWORD`).

## 🚀 Deployment Steps

In the `CapitalismBackend` directory:
```bash
docker compose up -d
```
This starts:
- **PostgreSQL**: Automatically initialized with `init.sql` (Schema) and `seeds.sql` (Data).
- (if uncommented) **pgAdmin**: Pre-registered with the `capitalism_db` database for easy visualization.

## 🔄 Maintenance & Updates
To completely reset the database and clear all persistent data:
```bash
docker compose down -v
docker compose up -d
```
> [!WARNING]
> This command will permanently delete all stored data, including accounts and transaction history.

## 🔗 Next Steps
The database is now ready to receive connections. You can now deploy the [Capitalism Middleware](../../CapitalismMiddleware/README.md) to start interacting with the banking engine.
