# 7. Aperçu de l'API Middleware

Ce document décrit les points d'entrée (endpoints) REST fournis par le Middleware pour le Mod Arma Reforger.

## 🔐 Authentification
Toutes les requêtes (sauf les vérifications de santé / health checks) doivent inclure l'en-tête suivant :
- `Authorization: Bearer <token>` : Votre clé API secrète (configurée dans le fichier `.env`).

---

## 👥 Entités (Entities)
Gérez les joueurs, les entreprises et les entités système.

### `GET /api/entities/{id}`
Récupère les détails d'une entité via son UUID.

### `GET /api/entities/uid/{gameUid}`
Récupère une entité via l'identifiant unique du jeu (Arma `PlayerId`).

### `POST /api/entities`
Crée une nouvelle entité.

---

## 💰 Comptes (Accounts)
Gérez les comptes bancaires et les soldes.

### `GET /api/accounts/{id}`
Récupère les détails d'un compte.

### `GET /api/accounts/iban/{iban}`
Trouve un compte par son IBAN.

### `GET /api/accounts/entity/{entityId}`
Liste tous les comptes appartenant à une entité.

### `POST /api/accounts`
Ouvre un nouveau compte pour une entité (Courant, Épargne, etc.).

---

## 💸 Transactions
Exécutez des opérations financières.

### `POST /api/transactions/transfer`
Transfère de l'argent entre deux comptes.
- **Taxe** : Une commission bancaire de 2% est appliquée aux transferts (hors salaires).
- **Forex** : Convertit automatiquement la devise si la source et la destination diffèrent.

### `POST /api/transactions/deposit`
Dépose du liquide sur un compte (ex: via un ATM).

### `POST /api/transactions/withdraw`
Retire du liquide d'un compte.

### `POST /api/transactions/card-payment`
Exécute un paiement via une carte bancaire virtuelle avec vérification du code PIN.

---

## 📜 Prêts (Loans)
### `POST /api/loans/issue`
Accorde un prêt à un joueur.

### `POST /api/loans/{id}/repay`
Remboursement manuel d'une partie ou de la totalité du prêt.

## 📜 Licences
### `GET /api/licenses/entity/{entityId}`
Vérifie quelles licences (permis de conduire, port d'arme, etc.) un joueur possède.

---

## 🏥 Santé & Statut
### `GET /health`
Vérifie si l'API et la base de données sont opérationnelles.
### `GET /scalar/v1`
Documentation API interactive (Swagger/Scalar).

---
*Retour au début : [Introduction au Data Core](1_Introduction.md)*
