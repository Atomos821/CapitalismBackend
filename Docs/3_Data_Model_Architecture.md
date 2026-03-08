# 3. Architecture & Modèle de Données

Ce document décrit l'architecture technique retenue pour le système économique ainsi que le modèle de données relationnel, conçu pour agir comme un véritable Système d'Information (SI) bancaire miniature.

## 1. Architecture Globale (Micro-Services)
Pour garantir la fiabilité, la sécurité et l'évolutivité du système, l'architecture est divisée en trois parties distinctes :

### 1.1. Frontend / Module Jeu (Arma Reforger Mod)
- **Emplacement :** `[Addon Directory]/addons/Capitalism`
- **Rôle :** Interface utilisateur (UI), objets physiques (ATM, liasses de billets dans l'inventaire), actions contextuelles du jeu (braquages, achats en boutique, salaires versés en jeu).
- **Fonctionnement :** Envoie des requêtes HTTP (REST) vers le Middleware pour effectuer les transactions. Le serveur Arma ne stocke **aucune** donnée bancaire persistante.

### 1.2. Middleware (API Gateway & Logique de Transition)
- **Emplacement :** `[Middleware Repository]`
- **Rôle :** Passerelle de sécurité entre le jeu et la base de données.
- **Fonctionnement :** 
  - Reçoit les requêtes du serveur Arma Reforger (ex: "Transférer 500$ de A vers B").
  - Gère les files d'attente (queues) pour éviter de surcharger le backend lors de transactions simultanées.
  - Valide les droits et l'intégrité de la requête (Anti-triche).
  - Gère les déconnexions : si le joueur se déconnecte pendant une requête, le middleware s'assure que la transaction aboutit ou est annulée proprement (Transaction ACID).
- **Déploiement :** Conteneurisé via Docker pour une isolation stricte et une portabilité maximale.

### 1.3. Backend (Core Banking System & BDD)
- **Emplacement :** `[Backend Repository]`
- **Rôle :** Le cœur du système bancaire. Héberge la base de données relationnelle (PostgreSQL) et la logique métier critique (calcul des soldes, génération des IBANs).
- **Fonctionnement :** Système fermé, accessible uniquement via le Middleware. Conçu pour être **scalable** : peut tourner de manière autonome sur un nœud unique (pour les petits serveurs) ou en cluster avec réplication/failover (pour les grosses communautés exigeant une Haute Disponibilité).
- **Déploiement :** Conteneurisé via Docker (Image officielle PostgreSQL). Réside dans un réseau virtuel isolé que seul le Middleware peut interroger.

---

## 2. Modèle de Données (Vrai SI Bancaire)

Pour éviter les failles (duplications, pertes) et assurer une parfaite traçabilité, le modèle doit être rigoureux et séparer les **Entités** (qui possède) des **Comptes** (où est l'argent).

### 2.1. Les Entités (entities)
Une entité est une personne capable de posséder un compte bancaire. *Note : Il existera une entité Système inaltérable appelée "World Cash" pour comptabiliser l'argent liquide physique circulant sur le serveur Arma et équilibrer la masse monétaire.*
- `id` : `UUID` (PRIMARY KEY)
- `type` : `VARCHAR(50)` NOT NULL (Ex: 'PHYSICAL_PERSON', 'MORAL_PERSON', 'SYSTEM')
- `name` : `VARCHAR(255)` NOT NULL (Nom RP du joueur ou nom de l'entreprise)
- `external_id` : `VARCHAR(255)` UNIQUE NULL (SteamID, UID Reforger, ou identifiant externe métier)
- `metadata` : `JSONB` DEFAULT '{}' (Champ fourre-tout ultra performant pour stocker des données libres sans modifier le schéma SQL limit: vip_level, last_login)
- `created_at` : `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `updated_at` : `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `deleted_at` : `TIMESTAMPTZ` NULL (Soft Delete : Les données financières ne sont jamais détruites, elles sont juste marquées supprimées)

### 2.2. Les Produits Bancaires (banking_products)
Définit les règles ("Contrats") des différents types de comptes (Ex: Compte Courant, Livret A, PEL).
- `id` : `VARCHAR(50)` PRIMARY KEY (Ex: 'CHECKING', 'SAVINGS_LIVRET_A')
- `name` : `VARCHAR(255)` NOT NULL (Nom lisible, ex: "Livret A")
- `interest_rate_percent` : `NUMERIC(5,2)` NOT NULL DEFAULT 0.00 (Taux de rémunération, ex: 3.00)
- `max_deposit_limit` : `BIGINT` NULL (Plafond de versement en centimes. Le code backend refusera les dépôts au-delà, mais laissera passer la capitalisation des intérêts)
- `withdrawal_fee_percent` : `NUMERIC(5,2)` NOT NULL DEFAULT 0.00 (Frais éventuels sur les retraits anticipés)
- `max_accounts_per_entity` : `INTEGER` NULL (Nombre maximum autorisé par joueur)
- `allowed_entity_types` : `JSONB` NOT NULL DEFAULT '[]' (Qui a le droit d'ouvrir ce compte? Ex: '["PHYSICAL_PERSON"]')
- `can_receive_external_transfers` : `BOOLEAN` NOT NULL DEFAULT TRUE (Autorise les virements provenant d'une autre entité)
- `can_pay_merchants` : `BOOLEAN` NOT NULL DEFAULT TRUE (Peut-on payer en boutique directement avec ce compte)
- `minimum_balance` : `BIGINT` NOT NULL DEFAULT 0 (Montant minimum pour garder le compte ouvert/l'ouvrir)

### 2.3. Les Comptes Bancaires (accounts)
Un compte est toujours rattaché à une Entité. *Un compte Système sera dédié au World Cash.*
- `id` : `UUID` PRIMARY KEY
- `iban` : `VARCHAR(34)` UNIQUE NOT NULL (Ex: "FR12345678A" ou "XX00000000A" pour le World Cash)
- `entity_id` : `UUID` NOT NULL REFERENCES entities(id)
- `product_type_id` : `VARCHAR(50)` NOT NULL REFERENCES banking_products(id)
- `balance` : `BIGINT` NOT NULL DEFAULT 0 CHECK (balance >= overdraft_limit) (Toujours en nombre entier de centimes)
- `currency` : `VARCHAR(3)` NOT NULL DEFAULT 'CAP'
- `status` : `VARCHAR(20)` NOT NULL DEFAULT 'ACTIVE' (ACTIVE, CLOSED)
- `can_withdraw` : `BOOLEAN` NOT NULL DEFAULT TRUE (Droit de virement sortant ou paiement, pouvant être révoqué par la Justice)
- `can_deposit` : `BOOLEAN` NOT NULL DEFAULT TRUE (Droit de dépôt entrant)
- `overdraft_limit` : `BIGINT` NOT NULL DEFAULT 0 (Plafond de découvert autorisé en négatif)
- `metadata` : `JSONB` DEFAULT '{}' (Spécificités au compte à la volée, ex: daily_withdrawal_limit)
- `created_at` : `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `updated_at` : `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `deleted_at` : `TIMESTAMPTZ` NULL

### 2.4. Les Transactions (transactions)
Pour une sécurité maximale (comme dans une vraie banque), le solde d'un compte devrait théoriquement être la somme de toutes ses transactions.
- `id` : `UUID` PRIMARY KEY
- `idempotency_key` : `UUID` NULL (Généré par le client/jeu, empêche les doubles transactions. Réutilisable si la transaction précédente a échoué.)
- `initiator_entity_id` : `UUID` NULL REFERENCES entities(id) (L'entité physique ayant déclenché l'ordre, crucial pour l'audit des procurations)
- `timestamp` : `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `source_account_id` : `UUID` NULL REFERENCES accounts(id)
- `destination_account_id` : `UUID` NULL REFERENCES accounts(id)
- `loan_id` : `UUID` NULL REFERENCES loans(id) (Optionnel, utile pour la traçabilité des remboursements)
- `amount` : `BIGINT` NOT NULL CHECK (amount > 0)
- `tax_amount` : `BIGINT` NOT NULL DEFAULT 0 (Montant confisqué automatiquement au passage pour l'état)
- `tax_destination_account_id` : `UUID` NULL REFERENCES accounts(id)
- `category` : `VARCHAR(50)` NULL (Sous-catégorie RP: SALARY, ITEM_SALE, VEHICLE_SALE, TICKET)
- `source_balance_after` : `BIGINT` NULL (Audit Ledger du compte source)
- `destination_balance_after` : `BIGINT` NULL (Audit Ledger du compte destinataire)
- `type` : `VARCHAR(50)` NOT NULL (TRANSFER, DEPOSIT, WITHDRAW, PAYCHECK, PURCHASE, FEE, INTEREST)
- `status` : `VARCHAR(20)` NOT NULL DEFAULT 'PENDING' (PENDING, COMPLETED, FAILED)
- `reference` : `TEXT` NULL (Motif ou note de la transaction)
- `metadata` : `JSONB` DEFAULT '{}' (Audit: coordonnées GPS, IP, ID de l'ATM utilisé)

### 2.5. Les Emprunts (loans)
Gère les crédits accordés par la banque ou entre joueurs/entreprises.
- `id` : `UUID` PRIMARY KEY
- `borrower_entity_id` : `UUID` NOT NULL REFERENCES entities(id)
- `total_amount` : `BIGINT` NOT NULL CHECK (total_amount > 0)
- `remaining_amount` : `BIGINT` NOT NULL CHECK (remaining_amount >= 0)
- `interest_rate_percent` : `NUMERIC(5,2)` NOT NULL
- `next_payment_date` : `TIMESTAMPTZ` NULL
- `status` : `VARCHAR(20)` NOT NULL DEFAULT 'ACTIVE'
- `created_at` : `TIMESTAMPTZ` NOT NULL DEFAULT NOW()

### 2.6. Les Permis et Licences (licenses)
Droits d'achat liés à l'économie (ex: Droit d'acheter des armes lourdes).
- `id` : `UUID` PRIMARY KEY
- `entity_id` : `UUID` NOT NULL REFERENCES entities(id)
- `license_type` : `VARCHAR(100)` NOT NULL (Ex: WEAPON_LICENSE)
- `acquired_at` : `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `expires_at` : `TIMESTAMPTZ` NULL

### 2.7. Taux de Change (forex_rates)
Gère un environnement multi-devises si besoin est.
- `base_currency` : `VARCHAR(3)` NOT NULL
- `target_currency` : `VARCHAR(3)` NOT NULL
- `rate` : `NUMERIC(10,4)` NOT NULL CHECK (rate > 0)
- `updated_at` : `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
*(Note: PRIMARY KEY composite sur base_currency, target_currency)*
*(Exemples:
    - `forex_rates` : `base_currency`=CRD, `target_currency`=USD, rate=1.0 (Parité)
    - `forex_rates` : `base_currency`=CRD, `target_currency`=RUB, rate=80.0 (1 CRD = 80 RUB)
    - `forex_rates` : `base_currency`=USD, `target_currency`=CRD, rate=1.0
)*

**Précision** : Le solde des comptes (`balance`) est un `BIGINT` représentant les **cents** (ex: 1000 = 10.00 CRD).

### 2.8. Comptes Joints et Copropriétaires (account_owners)
Permet à plusieurs joueurs physiques de partager la pleine propriété d'un compte.
- `account_id` : `UUID` NOT NULL REFERENCES accounts(id)
- `entity_id` : `UUID` NOT NULL REFERENCES entities(id)
- `role` : `VARCHAR(50)` NOT NULL DEFAULT 'CO_OWNER'
*(Note: PRIMARY KEY composite sur account_id, entity_id)*

### 2.9. Procurations et Mandats (account_proxies)
Donne le droit de dépenser l'argent d'un compte (ex: entreprise) à un autre joueur, avec des limites.
- `id` : `UUID` PRIMARY KEY
- `account_id` : `UUID` NOT NULL REFERENCES accounts(id)
- `proxy_entity_id` : `UUID` NOT NULL REFERENCES entities(id)
- `daily_spending_limit` : `BIGINT` NULL (Limite de dépenses par jour)
- `can_transfer_money` : `BOOLEAN` NOT NULL DEFAULT FALSE (Droit de virer de l'argent du compte d'enteprise sur son propre compte, dangereux !)
- `can_buy_from_merchants` : `BOOLEAN` NOT NULL DEFAULT TRUE (Droit d'acheter des objets pour la faction)
- `can_withdraw_cash` : `BOOLEAN` NOT NULL DEFAULT FALSE (Droit d'aller à l'ATM retirer le cash de l'entreprise)
- `created_at` : `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `expires_at` : `TIMESTAMPTZ` NULL (Date de fin de la procuration)

### 2.10. Prélèvements Automatiques (subscriptions)
Factures récurrentes (loyers, téléphones, impôts).
- `id` : `UUID` PRIMARY KEY
- `source_account_id` : `UUID` NOT NULL REFERENCES accounts(id)
- `destination_account_id` : `UUID` NOT NULL REFERENCES accounts(id)
- `amount` : `BIGINT` NOT NULL CHECK (amount > 0)
- `frequency_hours` : `INTEGER` NOT NULL CHECK (frequency_hours > 0)
- `last_processed_at` : `TIMESTAMPTZ` NULL
- `status` : `VARCHAR(20)` NOT NULL DEFAULT 'ACTIVE'
- `created_at` : `TIMESTAMPTZ` NOT NULL DEFAULT NOW()

### 2.11. Cartes Bancaires (bank_cards)
Objet physique en jeu, lié à un compte pour autoriser les paiements.
- `id` : `UUID` PRIMARY KEY (peut correspondre à un ID d'objet dans l'inventaire Arma)
- `account_id` : `UUID` NOT NULL REFERENCES accounts(id)
- `pin_hash` : `VARCHAR(255)` NOT NULL (Hash du code PIN à 4 chiffres)
- `failed_pin_attempts` : `INTEGER` NOT NULL DEFAULT 0 (Sécurité: bloque la carte après 3 erreurs)
- `status` : `VARCHAR(20)` NOT NULL DEFAULT 'ACTIVE' (ACTIVE, BLOCKED, EXPIRED)
- `daily_payment_limit` : `BIGINT` NULL (Plafond de paiement physique indépendant du compte)
- `created_at` : `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `expires_at` : `TIMESTAMPTZ` NULL
- `deleted_at` : `TIMESTAMPTZ` NULL

### 2.12. File d'Attente des Transactions (transaction_queue) - *Protection Anti-Crash*
Garantit qu'aucune transaction initiée par le jeu ne soit perdue si le Middleware crash avant le traitement. Implémente le pattern "Outbox" ou "Job Queue".
- `id` : `UUID` PRIMARY KEY
- `payload` : `JSONB` NOT NULL (Le contenu brut de la requête de virement reçue d'Arma)
- `session_id` : `VARCHAR(255)` NULL (Pour le suivi de la session en cas de litige)
- `status` : `VARCHAR(20)` NOT NULL DEFAULT 'PENDING' (PENDING, PROCESSING, COMPLETED, FAILED)
- `error_message` : `TEXT` NULL (Raison de l'échec si le statut est FAILED)
- `created_at` : `TIMESTAMPTZ` NOT NULL DEFAULT NOW()
- `processed_at` : `TIMESTAMPTZ` NULL

**Stratégie de traitement (Middleware C#)** :
- **Polling Asynchrone** : Un service d'arrière-plan (Background Worker) lira cette table en continu avec `SELECT ... FOR UPDATE SKIP LOCKED` pour éviter les Race Conditions. Il traitera les virements de façon séquentielle sans bloquer la base de données.
- **Garbage Collection (Nettoyage)** : Un Cron Job (Tâche planifiée) s'exécutera périodiquement (ex: toutes les nuits à 04h00) pour effectuer un `DELETE` automatique des transactions ayant le statut `COMPLETED` ou `FAILED` datant de plus de 7 jours. Cela garantit que cette table ne grossira pas indéfiniment et préserve les performances d'accès de la base.

### 2.13. Schéma Relationnel et Cardinalités (MCD/MLD)
Afin de bien comprendre comment ces tables interagissent entre elles via leurs contraintes de clés étrangères (Foreign Keys), voici la cartographie exacte de leurs relations cardinales :

#### Relations 1:N (One-to-Many / Un-à-Plusieurs)
- **`entities` (1) ─── `accounts` (N)** : Un joueur ou entreprise peut posséder de zéro à plusieurs comptes en banque, mais un compte bancaire appartient (principalement) à une seule entité.
- **`banking_products` (1) ─── `accounts` (N)** : Un produit bancaire (ex: "Livret A") s'applique à une infinité de comptes, mais un compte obéit à un et un seul contrat de produit.
- **`accounts` (1) ─── `transactions` (N)** *(en tant que compte source)* : Un compte peut être à l'origine de multiples virements sortants.
- **`accounts` (1) ─── `transactions` (N)** *(en tant que compte de destination)* : Un compte peut recevoir de multiples virements entrants.
- **`entities` (1) ─── `licenses` (N)** : Un joueur peut détenir plusieurs licences (Armes, Hélico, Chef d'Entreprise).
- **`entities` (1) ─── `loans` (N)** : Un joueur/entreprise peut souscrire à plusieurs emprunts en même temps.
- **`loans` (1) ─── `transactions` (N)** : Un emprunt unique fera l'objet de multiples transactions de remboursement (mensualités).
- **`accounts` (1) ─── `bank_cards` (N)** : Un même compte courant principal peut se voir délivrer plusieurs cartes bancaires (ex: si le joueur possède un compte Entreprise, il peut créer 3 cartes pour ses 3 employés pointant vers ce même compte).

#### Relations N:N (Many-to-Many / Plusieurs-à-Plusieurs)
*Ces relations nécessitent une table de liaison (Junction Table) dans une architecture SQL.*
- **`entities` (N) ─── [ `account_owners` ] ─── `accounts` (N)** : (Comptes Joints). 
  - *Lecture :* Un compte peut appartenir solidairement à plusieurs entités (ex: un couple de joueurs). 
  - *Lecture inverse :* Une entité peut être co-titulaire de plusieurs comptes conjoints.
- **`entities` (N) ─── [ `account_proxies` ] ─── `accounts` (N)** : (Procurations).
  - *Lecture :* Un compte d'entreprise peut voir sa gestion déléguée à plusieurs employés.
  - *Lecture inverse :* Un joueur peut avoir la procuration sur plusieurs entreprises différentes.
- **`accounts` (N) ─── [ `subscriptions` ] ─── `accounts` (N)** : (Prélèvements Autos).
  - *Lecture :* Un compte A peut émettre plusieurs prélèvements (Netflix, Loyer, Amende).
  - *Lecture inverse :* Un compte B (le Concessionnaire) peut recevoir des centaines de prélèvements autos de centaines de comptes clients.

#### Représentation Visuelle Simplifiée (Mermaid Line)
`(entities)` ---> `(accounts)` ---> `(transactions)`
`|-->(licenses)`  `|-->(bank_cards)`     `|-->(transaction_queue)`
`|-->(loans)`     `|-->(subscriptions)`

---

## 3. Technologies Choisies
- **Backend / BDD :** **PostgreSQL** (Robustesse ACID parfaite, réplication optionnelle pour Haute Disponibilité).
- **Middleware :** **C# (.NET 8+)** (Hautes performances, écosystème ASP.NET Core mature, multiplateforme Linux/Docker natif, grande proximité avec l'EnfusionScript d'Arma Reforger).
- **Communication Arma -> Middleware :** API REST (`RestApi` dans l'Enfusion Engine).

---
*Prochaine étape : [Spécifications Techniques](4_Technical_Specifications.md)*
