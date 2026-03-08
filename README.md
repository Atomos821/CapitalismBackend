# 🏦 Capitalism - Data Core

**Capitalism - Data Core** est un moteur de persistance financier robuste et agnostique, conçu pour gérer des économies complexes et persistantes. Bien qu'initialement développé pour des simulations de jeux, sa structure est strictement conforme aux principes de la comptabilité en partie double et peut être utilisée par n'importe quelle application nécessitant un registre bancaire fiable.

Il constitue le **cœur de données** (Source of Truth) et la couche de persistance de l'écosystème Capitalism. Il assure le stockage immuable, la définition du schéma relationnel et le paramétrage initial des produits financiers.

## 🎯 Vision et Objectifs
Le Data Core n'est pas qu'une simple base de données ; c'est un coffre-fort numérique conçu pour :
*   **L'Agnosticisme applicatif** : Interfaçable avec n'importe quel middleware (C#, Python, Node.js) ou simulateur.
*   **L'Infaillibilité financière** : Utilisation massive de contraintes SQL pour empêcher techniquement le double-débit ou les soldes incohérents.
*   **La Haute Disponibilité** : Prêt pour la production via Docker, avec indexation et partitionnement pour des millions de transactions.

## ✨ Fonctionnalités Clés
*   **Registre Multi-Devises** : Support natif du Change (Forex) et de la taxation automatique.
*   **Structure d'Entités Abstraite** : Gestion unifiée des Individus, Entreprises, Factions et États.
*   **Monétique Complète** : Gestion de cartes bancaires (PIN, plafonds, cycles de vie).
*   **Système de Prêts & Intérêts** : Moteur de calcul et de suivi des dettes et rendements.
*   **Délégations & Procurations** : Contrôles granulaires pour les accès partagés (comptes de faction/entreprise).

## 📂 Structure du Projet
- `init.sql` : Définition du schéma technique (Tables, Index, Triggers).
- `seeds.sql` : Configuration métier par défaut (Banques, Offres, Taux).
- `docker-compose.yml` : Orchestration prête à l'emploi (PostgreSQL 15 + pgAdmin).
- `Docs/` : Documentation approfondie.
  - [1. Introduction au Data Core](Docs/1_Introduction.md)
  - [2. Capacités Fonctionnelles](Docs/2_Functional_Capabilities.md)
  - [3. Architecture & Modèle de Données](Docs/3_Data_Model_Architecture.md)
  - [4. Spécifications Techniques](Docs/4_Technical_Specifications.md)
  - [5. Logique Financière du Système](Docs/5_Core_Financial_Logic.md)
  - [6. Guide de Déploiement](Docs/6_Project_Deployment.md)
  - [7. Aperçu de l'API Middleware](Docs/7_Middleware_API_Preview.md)

## 🚀 Démarrage Rapide

### 1. Prérequis
*   Docker & Docker Compose.
*   Copiez `.env.example` vers `.env` et configurez vos secrets.

### 2. Lancement
```bash
docker-compose up -d
```
Cela démarrera :
*   **PostgreSQL** sur le port `5432` (par défaut).
*   **pgAdmin** sur le port `5050` (par défaut).

## 🛡️ Licence
Ce projet est sous licence **Propriétaire (Tous droits réservés)**. Voir le fichier [LICENSE](LICENSE) pour plus de détails. Toute modification ou redistribution est interdite sans autorisation.