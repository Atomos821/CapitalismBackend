# 1. Introduction au Data Core

## Vue d'ensemble
`Capitalism - Data Core` est un moteur de persistance financier et un orchestrateur d'infrastructure pour le système économique "Capitalism". Il assure la gestion des actifs, la définition du schéma relationnel bancaire et la configuration initiale des produits financiers pour des écosystèmes persistants.

## Philosophie du dépôt
Ce dépôt suit un principe de **découplage strict** :
- Il ne contient **aucune logique métier applicative** (pas de code C#, pas de calculs complexes).
- Il garantit l'**intégrité des données** via des contraintes SQL natives (CHECK, UNIQUE, Foreign Keys).
- Il est conçu pour être **autonome** : une fois lancé via Docker, il fournit une infrastructure prête pour n'importe quel Middleware.

## Composants Clés
1. **Base de Données (PostgreSQL)** : Le moteur de stockage.
2. **Registre (Ledger)** : La table de transactions hautement performante.
3. **Administration (pgAdmin)** : Outil visuel de gestion du noyau.

## Flux d'initialisation
À chaque démarrage d'un nouveau conteneur, les scripts sont exécutés dans cet ordre :
1. `init.sql` : Création des structures.
2. `seeds.sql` : Injection des données de base.

---
*Prochaine étape : [Capacités Fonctionnelles](2_Functional_Capabilities.md)*
