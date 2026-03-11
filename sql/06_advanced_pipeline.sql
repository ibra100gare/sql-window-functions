-- ============================================================
-- 06 - CAS AVANCÉ : PIPELINE ANALYTIQUE COMPLET
-- Combiner plusieurs window functions dans un seul pipeline CTE
-- Tables : CO.ORDERS, CO.CUSTOMERS, CO.STORES
-- ============================================================


-- ------------------------------------------------------------
-- 6.1 Dashboard client : toutes les métriques en une requête
-- ------------------------------------------------------------
WITH client_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        o.order_total,

        -- Numéro séquentiel de la commande par client
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id
            ORDER BY     o.order_date
        )                                                    AS n_commande,

        -- Montant de la commande précédente (NULL pour la 1ère)
        LAG(o.order_total) OVER (
            PARTITION BY o.customer_id
            ORDER BY     o.order_date
        )                                                    AS prev_total,

        -- CA cumulé par client
        SUM(o.order_total) OVER (
            PARTITION BY o.customer_id
            ORDER BY     o.order_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                                    AS ca_cumule_client,

        -- CA total du client (toutes commandes confondues)
        SUM(o.order_total) OVER (
            PARTITION BY o.customer_id
        )                                                    AS ca_total_client

    FROM co.orders o
),
enriched AS (
    SELECT
        *,
        -- Évolution % par rapport à la commande précédente
        ROUND(
            100.0 * (order_total - prev_total) / NULLIF(prev_total, 0),
            1
        )                                                    AS evol_pct,

        -- Rang global parmi tous les clients selon CA total
        RANK() OVER (ORDER BY ca_total_client DESC)          AS rang_global_client,

        -- Segment : top 33% / milieu / bas
        NTILE(3) OVER (ORDER BY ca_total_client DESC)        AS segment_num

    FROM client_orders
)
SELECT
    customer_id,
    order_id,
    order_date,
    order_total,
    n_commande,
    COALESCE(CAST(evol_pct AS VARCHAR) || '%', 'Première commande')  AS evolution,
    ca_cumule_client,
    ca_total_client,
    rang_global_client,
    CASE segment_num
        WHEN 1 THEN '🥇 Premium'
        WHEN 2 THEN '🥈 Standard'
        WHEN 3 THEN '🥉 Basic'
    END                                                      AS segment
FROM enriched
ORDER BY customer_id, order_date;


-- ------------------------------------------------------------
-- 6.2 Analyse magasin : performance vs moyenne + tendance
-- ------------------------------------------------------------
WITH store_monthly AS (
    SELECT
        s.store_id,
        s.store_name,
        DATE_TRUNC('month', o.order_date)                    AS mois,
        SUM(o.order_total)                                   AS ca_mensuel
    FROM co.orders  o
    JOIN co.stores  s ON s.store_id = o.store_id
    GROUP BY s.store_id, s.store_name, DATE_TRUNC('month', o.order_date)
)
SELECT
    store_name,
    mois,
    ca_mensuel,

    -- Moyenne du magasin sur les 3 derniers mois
    ROUND(AVG(ca_mensuel) OVER (
        PARTITION BY store_id
        ORDER BY     mois
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                                    AS moy_mobile_3m,

    -- CA cumulé du magasin
    SUM(ca_mensuel) OVER (
        PARTITION BY store_id
        ORDER BY     mois
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                        AS ca_cumule_store,

    -- Moyenne de tous les magasins ce mois-là
    ROUND(AVG(ca_mensuel) OVER (PARTITION BY mois), 2)       AS moy_tous_stores_ce_mois,

    -- Écart au-dessus/en-dessous de la moyenne
    ROUND(ca_mensuel - AVG(ca_mensuel) OVER (PARTITION BY mois), 2)  AS ecart_a_la_moy,

    -- Rang du magasin ce mois
    RANK() OVER (PARTITION BY mois ORDER BY ca_mensuel DESC) AS rang_ce_mois

FROM store_monthly
ORDER BY store_name, mois;


-- ------------------------------------------------------------
-- 6.3 Détection d'anomalies : commandes anormalement élevées
-- (> 2x la moyenne mobile du client)
-- ------------------------------------------------------------
WITH client_stats AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        order_total,
        AVG(order_total) OVER (
            PARTITION BY customer_id
            ORDER BY     order_date
            ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING   -- moyenne des 3 commandes AVANT
        )                                               AS moy_3_precedentes
    FROM co.orders
)
SELECT
    customer_id,
    order_id,
    order_date,
    order_total,
    ROUND(moy_3_precedentes, 2)                         AS moy_3_precedentes,
    CASE
        WHEN order_total > 2 * moy_3_precedentes THEN '🚨 Anomalie'
        WHEN order_total > 1.5 * moy_3_precedentes THEN '⚠️  Élevée'
        ELSE '✅ Normale'
    END                                                 AS alerte
FROM client_stats
WHERE moy_3_precedentes IS NOT NULL
ORDER BY customer_id, order_date;
