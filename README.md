# 🪟 SQL Window Functions — Guide Pratique

Projet pédagogique complet sur les **fonctions de fenêtrage SQL**, basé sur un schéma e-commerce réel.

---

## 📦 Schéma de la base de données

```
CO.CUSTOMERS     → Clients
CO.ORDERS        → Commandes
CO.ORDER_ITEMS   → Lignes de commande
CO.PRODUCTS      → Produits
CO.INVENTORY     → Inventaire
CO.SHIPMENTS     → Expéditions
CO.STORES        → Magasins
```

---

## 📂 Structure du projet

```
sql-window-functions/
├── sql/
│   ├── 01_ranking_functions.sql      # ROW_NUMBER, RANK, DENSE_RANK
│   ├── 02_lag_lead.sql               # LAG, LEAD
│   ├── 03_aggregate_windows.sql      # SUM/AVG/COUNT OVER
│   ├── 04_first_last_nth_value.sql   # FIRST_VALUE, LAST_VALUE, NTH_VALUE
│   ├── 05_distribution_functions.sql # NTILE, PERCENT_RANK, CUME_DIST
│   └── 06_advanced_pipeline.sql      # Pipeline analytique complet
└── README.md
```

---

## 🚀 Fonctions couvertes

| Fichier | Fonctions | Cas pratiques |
|--------|-----------|---------------|
| `01_ranking_functions.sql` | `ROW_NUMBER`, `RANK`, `DENSE_RANK` | Numérotation commandes, top-N par catégorie, déduplication |
| `02_lag_lead.sql` | `LAG`, `LEAD` | Évolution MoM, délai expédition, croissance CA |
| `03_aggregate_windows.sql` | `SUM/AVG/COUNT/MIN/MAX OVER` | Running total, moyenne mobile, % du total |
| `04_first_last_nth_value.sql` | `FIRST_VALUE`, `LAST_VALUE`, `NTH_VALUE` | Première commande, dernier statut, N-ième valeur |
| `05_distribution_functions.sql` | `NTILE`, `PERCENT_RANK`, `CUME_DIST` | Quartiles clients, déciles commandes, percentiles |
| `06_advanced_pipeline.sql` | Tout combiné | Dashboard client, analyse magasin, détection anomalies |

---

## 🧠 Syntaxe de base

```sql
fonction() OVER (
    PARTITION BY colonne_de_groupement   -- optionnel
    ORDER BY     colonne_de_tri          -- optionnel
    ROWS BETWEEN ...                     -- optionnel
)
```

### Frames courantes

```sql
-- Toutes les lignes depuis le début jusqu'à la ligne courante
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

-- Toutes les lignes de la partition
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

-- Fenêtre glissante de 3 lignes (N-2, N-1, N)
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW

-- Les 3 lignes avant la ligne courante (pas la courante)
ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
```

---

## ⚠️ Pièges à éviter

1. **`LAST_VALUE` sans frame explicite** → retourne toujours la ligne courante par défaut. Toujours ajouter `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`.

2. **`RANK` vs `DENSE_RANK`** → `RANK` saute des numéros en cas d'ex-aequo (1, 1, 3...), `DENSE_RANK` non (1, 1, 2...).

3. **`LAG`/`LEAD` retournent `NULL`** pour les lignes sans précédent/suivant — utiliser le 3ème argument pour une valeur par défaut : `LAG(col, 1, 0)`.

4. **`OVER ()` sans rien** = fenêtre = toute la table. Utile pour calculer un % du total global.

---

## 💡 Pattern Top-N par groupe

Le pattern le plus utilisé en SQL analytique :

```sql
WITH ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY groupe ORDER BY valeur DESC) AS rang
    FROM table
)
SELECT *
FROM ranked
WHERE rang <= N;
```

---

## 📄 Licence

MIT — libre d'utilisation à des fins éducatives.
