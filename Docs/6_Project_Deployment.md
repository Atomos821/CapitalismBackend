# 6. Guide de Déploiement

Ce guide explique comment déployer le système économique Capitalism en utilisant Docker.

## 📋 Prérequis
- **Docker** & **Docker Compose** installés.
- Ports `5432` (Base de données), `5050` (pgAdmin), et `8080` (API) disponibles sur l'hôte.

## 🔨 Configuration
1.  **Backend** : Copiez `d:\GitHub\CapitalismBackend\.env.example` vers `.env` et mettez à jour les identifiants.
2.  **Middleware** : Copiez `d:\GitHub\CapitalismMiddleware\.env.example` vers `.env`. Mettez à jour `API_CONNECTION_STRING` pour pointer vers votre base de données et définissez une clé `API_KEY` robuste.

## 🚀 Étapes de Déploiement

### 1. Base de données & Infrastructure
Dans le répertoire `CapitalismBackend` :
```bash
docker compose up -d
```
Ceci démarre :
- **PostgreSQL** : Initialisé automatiquement avec `init.sql`.
- **pgAdmin** : Pré-enregistré avec la base de données `capitalism_core`.

### 2. API Middleware
Dans le répertoire `CapitalismMiddleware` :
```bash
docker compose up --build -d
```
Ceci construit et démarre l'API C# ASP.NET Core.

## 🔍 Vérification
- **Santé de l'API** : Visitez `http://localhost:8080/health`. Doit retourner "Healthy".
- **Documentation** : Visitez `http://localhost:8080/scalar/v1` pour tester l'API de manière interactive.
- **Administration DB** : Visitez `http://localhost:5050` pour gérer les données via pgAdmin.

## 🔄 Maintenance & Mises à jour
Pour réinitialiser complètement la base de données :
```bash
docker compose down -v
docker compose up -d
```
> [!WARNING]
> Cette commande supprimera définitivement tous les comptes joueurs et l'historique des transactions.

---
*Prochaine étape : [Aperçu de l'API Middleware](7_Middleware_API_Preview.md)*
