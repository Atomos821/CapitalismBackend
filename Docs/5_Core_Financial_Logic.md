# 5. Logique Financière du Système
---

## 🏦 Écosystème Multi-Banques
Le système gère plusieurs marques bancaires indépendantes, chacune avec sa propre spécialisation et monnaie de compte.

### 1. Union Bank (ID: `UB`)
- **Cible** : Civil et petites entreprises.
- **Monnaie de compte** : **EUR**.
- **Produits** :
    - `UB_CHECKING` : Compte courant standard (Frais: 1.00%).
    - `UB_SAVINGS` : Livret d'épargne (Intérêts: 3.00%, Pas de retraits cash).

### 2. Talos Financial (ID: `TF`)
- **Cible** : Secteur défense, mercenaires et opérations tactiques.
- **Monnaie de compte** : **RUB**.
- **Produits** :
    - `TF_OPERATIVE` : Compte opérationnel haute liquidité (Frais: 0.20%, Solde min: 500k).
    - `TF_WAR_CHEST` : Coffre de défense (Intérêts: 1.50%, Pas de paiement marchand).

### 3. Vanguard Trade & Trust (ID: `VTT`)
- **Cible** : International, gouvernements et gros capitaux.
- **Monnaie de compte** : **USD**.
- **Produits** :
    - `VTT_BUSINESS` : Business Pro Plus (Multi-devises, Frais virements réduits).

## 💰 Types de Prêts (Loans)
Le middleware supporte plusieurs types de crédits gérés via `LoanService` :
- **Prêt Personnel** : Taux fixe, remboursement hebdomadaire automatique.
- **Crédit de Guerre (Talos)** : Destiné à l'achat d'équipement, taux préférentiel.
- **Bail Commercial** : Pour les entreprises, plafonds élevés.

## 💸 Logique des Frais (Taxation)
Les frais sont calculés de manière "On-Top" (au-dessus du montant demandé).

### Pour les Virements (Transfers) :
Si un joueur A envoie **1 000 CRD** à un joueur B avec des frais de 1% :
1.  **Montant débité** du compte A : **1 010 CRD** (1 000 + 10 de taxe).
2.  **Montant crédité** au compte B : **1 000 CRD**.

### Pour les Retraits (Withdrawals) :
Si un joueur retire **500 CRD** avec des frais de 0.5% :
1.  **Montant débité** du compte : **502.5 CRD** (500 + 2.5 de taxe).
2.  **Cash reçu** par le joueur : **500 CRD**.

## 💱 Conversion Forex (Modèle Pivot)
Le système utilise une monnaie de référence fictive appelée **CRD** (Crédits) comme pivot central. Cela permet de convertir n'importe quelle paire de devises sans avoir à définir chaque combinaison manuellement.

### Fonctionnement du Pivot :
Lorsqu'un virement a lieu entre un compte **RUB** et un compte **EUR** :
1.  Le système cherche un taux direct `RUB -> EUR`.
2.  S'il n'existe pas, il calcule le taux via le pivot : `(RUB -> CRD) * (CRD -> EUR)`.
3.  **Avantage** : Pour ajouter une nouvelle devise (ex: GBP), il suffit de définir son taux par rapport au CRD.

### Précision et Sécurité :
- **Abstraction** : Le CRD est une unité de compte technique invisible. Les banques affichent les montants dans leur monnaie locale (EUR, USD, RUB).
- **Taxation** : La taxe est calculée sur le montant source *avant* la conversion pivot.
- **Types SQL** : Les taux utilisent `NUMERIC(18,8)` pour garantir 8 décimales de précision sans perte.

## 👷 Workers d'Arrière-plan
Le système s'auto-régule via plusieurs services de fond :
1. **TransactionOutboxWorker** : Traite la file d'attente asynchrone des transactions.
2. **InterestCapitalizationWorker** : Calcule et crédite les intérêts quotidiennement.
3. **SubscriptionWorker** : Gère les paiements périodiques (loyers, factures).
4. **LoanRepaymentWorker** : Collecte automatisée des dettes.

## 🔐 Sécurité & Précision
1.  **Tout en Entiers (`long`)** : L'argent est stocké en **cents**. Aucun type `float` n'est utilisé.
2.  **Procurations** : Les mandataires (`Proxies`) ont des droits granulaires et des plafonds de dépense suivis par `initiator_entity_id`.

---
*Prochaine étape : [Guide de Déploiement](6_Project_Deployment.md)*
