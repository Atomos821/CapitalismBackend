# 2. Capacités Fonctionnelles du Data Core

Ce document présente les capacités métiers et les produits financiers que le socle de données `Capitalism - Data Core` peut supporter. Il définit le potentiel fonctionnel du système, indépendamment de ses interfaces ou de ses applications tierces.

---

## 1. 👥 Gestion des Acteurs Économiques
Le système repose sur un modèle d'entités abstrait permettant de gérer différents profils :
*   **Individus** : Comptes personnels pour les joueurs.
*   **Organisations** : Entreprises, syndicats, factions ou groupes gouvernementaux.
*   **Service Système** : Entités de régulation ou banques centrales.
*   **Historique et Traçabilité** : Chaque acteur dispose d'un cycle de vie complet, permettant de conserver les archives comptables même après la dissolution d'une organisation ou le départ d'un individu.

## 2. 🏛️ Système Bancaire Multi-Enseignes
La structure permet la coexistence de plusieurs institutions bancaires au sein d'une même économie :
*   **Identité Propre** : Chaque banque peut avoir son propre nom, sa description et sa devise de référence.
*   **Paramétrage Visuel** : La configuration permet d'adapter l'apparence des interfaces (couleurs, logos) selon l'établissement choisi.

## 3. 💳 Catalogue de Produits Bancaires
Le système permet de modéliser une large gamme de produits financiers configurables dynamiquement.

### 3.1 Comptes de Dépôt
Le catalogue permet de créer des comptes variés (Courant, Épargne, Professionnel) définis par :
*   **Rendement** : Taux d'intérêt sur les soldes.
*   **Accessibilité** : Permissions modulables pour les retraits, les dépôts et les paiements.
*   **Tarification** : Frais de retrait et de virement personnalisables par produit.
*   **Contraintes de Solde** : Montants minimums obligatoires ou plafonds de dépôt.

### 3.2 Solutions de Financement (Prêts)
La base supporte nativement des produits de crédit avec :
*   Taux d'intérêt spécifiques.
*   Rythme de remboursement flexible (hebdomadaire, mensuel, etc.).
*   Limites de montant adaptées à chaque type de clientèle.

## 4. 🔒 Protection et Gestion des Risques
Des mécanismes de contrôle sont intégrés nativement au niveau de la donnée :
*   **Gestion du Découvert** : Limite de tolérance négative configurable par compte, empêchant techniquement tout dépassement non autorisé.
*   **Verrouillage de Sécurité** : Capacité de suspendre les opérations d'un compte (gel des fonds) pour des raisons de sécurité.

## 5. 🤝 Propriété Partagée et Délégation
Le modèle permet une gestion complexe de l'accès aux fonds :
*   **Comptes-Joints** : Plusieurs individus ou gérants peuvent être copropriétaires d'un même compte.
*   **Mandats (Procurations)** : Système permettant de déléguer l'accès à un compte avec des restrictions précises (limites de dépenses journalières, interdiction de retrait de liquide).

## 6. 🏧 Réseau Monétique (Cartes Bancaires)
Le système gère des cartes de paiement virtuelles ou physiques :
*   **Sécurisation** : Protection par code PIN et blocage automatique après plusieurs erreurs.
*   **Suivi des Plafonds** : Limites de paiement journalières indépendantes du solde disponible.

## 7. ⏳ Automatisation des flux (Prélèvements et Engagements)
Le socle permet de programmer des transactions récurrentes ou différées :
*   **Récurrence** : Salaires, loyers, abonnements ou taxes prélevés automatiquement à intervalle régulier.
*   **Planification** : Ordres de virement programmés pour une exécution future.

## 8. 💱 Échanges et Fiscalité
Le registre des transactions intègre nativement des concepts de gestion avancée :
*   **Fiscalité à la source** : Calcul et redirection automatique des taxes vers les comptes de l'administration.
*   **Gestion des Changes** : Support des virements multi-devises avec enregistrement du taux appliqué au moment de l'opération.

---
*Prochaine étape : [Architecture & Modèle de Données](3_Data_Model_Architecture.md)*
