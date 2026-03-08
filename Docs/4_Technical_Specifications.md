# 4. Spécifications Techniques du Data Core

Ce document détaille les mécanismes techniques (SQL, Triggers, Contraintes) utilisés pour implémenter les fonctionnalités bancaires au sein de la base de données PostgreSQL.

---

## 1. 🏗️ Architecture du Registre (Ledger)
La table `transactions` utilise des techniques avancées pour garantir l'intégrité et la performance du Grand Livre.

### 1.1 Partitionnement Temporel
Pour maintenir des performances constantes malgré un volume important de données, la table `transactions` est partitionnée :
*   **Type** : `RANGE (timestamp)`.
*   **Mécanisme** : Utilisation d'un trigger `BEFORE INSERT` sur la partition par défaut.
*   **Automatisation** : La fonction `create_transaction_partition_and_insert()` détecte le besoin de nouvelles partitions mensuelles et les crée dynamiquement via SQL préparé (`EXECUTE`).

### 1.2 Idempotence Stricte
Le système empêche techniquement le double-traitement d'une même intention de transaction :
*   **Index Unique Partiel** : `idx_transactions_idempotency` sur `(idempotency_key, timestamp)`.
*   **Condition** : `WHERE status != 'FAILED'`. Cela permet de retenter une transaction qui a précédemment échoué, tout en bloquant toute duplication d'une transaction réussie ou en cours.

## 2. 🛡️ Contrôles d'Intégrité Critique
La base de données agit comme le dernier rempart de la logique métier.

### 2.1 Gestion du Découvert (Overdraft)
Le contrôle du solde ne repose pas sur le middleware mais sur une contrainte SQL native :
*   **Contrainte** : `CONSTRAINT chk_balance_overdraft CHECK (balance >= overdraft_limit)`.
*   **Avantage** : Aucune application, même malveillante ou buggée, ne peut forcer un compte en dessous de sa limite autorisée.

### 2.2 Sécurité des Cartes
La table `bank_cards` gère son propre état de sécurité :
*   **PIN** : Stocké sous forme de hash via `pin_hash`.
*   **Tentatives** : Incrémentation atomique du champ `failed_pin_attempts`, permettant un blocage au niveau de la donnée indépendamment de la session utilisateur.

## 3. 🧩 Modélisation Objet et Extensibilité
Le schéma utilise les capacités modernes de PostgreSQL pour rester flexible.

### 3.1 Utilisation du JSONB
Le type de donnée `JSONB` est utilisé massivement pour stocker les métadonnées (`entities`, `banks`, `accounts`) et les configurations (`banking_products.allowed_entity_types`).
*   **Performance** : Permet l'indexation des propriétés à l'intérieur du JSON.
*   **Flexibilité** : Permet d'ajouter des propriétés sans migration de schéma.

### 3.2 Hiérarchie de Produits
Les comptes ne sont pas des entités isolées, ils héritent des propriétés de `banking_products` :
*   **Mapping** : `accounts.product_type_id` → `banking_products.id`.
*   **Injection de Logique** : Les taux et frais sont lus dynamiquement depuis le produit, évitant la duplication de donnée par compte.

## 4. 🔄 Automatisation par Triggers
Les mises à jour de métadonnées et la synchronisation temporelle sont automatisées :
*   **Horodatage** : Trigger `update_updated_at_column` sur presque toutes les tables pour garantir une piste d'audit fiable.
*   **Calcul des Intérêts/Prélèvements** : Bien que déclenchés par le Middleware, la structure des tables `subscriptions` et `loans` (avec `last_processed_at` et `next_payment_date`) permet de reconstruire l'état complet des dettes et engagements à tout moment.

## 5. 🔀 Gestion des Échanges Multi-Devises
La table `transactions` est conçue pour l'audit financier complet :
*   **Double Saisie** : Stockage du montant source et du montant de destination (`destination_amount`).
*   **Taux de Change** : Capture du `exchange_rate` effectif, assurant que les rapports financiers ultérieurs restent exacts même si les taux de change globaux évoluent.

---
*Prochaine étape : [Logique Financière & Core Engine](5_Core_Financial_Logic.md)*
