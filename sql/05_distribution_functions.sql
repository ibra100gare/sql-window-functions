-- ============================================================
-- 05 - DISTRIBUTION & SEGMENTATION
-- NTILE() | PERCENT_RANK() | CUME_DIST()
-- Tables : CO.ORDERS, CO.CUSTOMERS, CO.PRODUCTS
-- ============================================================


-- ------------------------------------------------------------
-- 5.1 NTILE(4) : Segmenter les clients en quartiles (RFM simplifié)
-- ------------------------------------------------------------
WITH ca_clients AS (
    SELECT
        customer_id,
        SUM(order_total) AS ca_total
    FROM co.orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    ca_total,
    NTILE(4) OVER (ORDER BY ca_total DESC)                   AS quartile,
    CASE NTILE(4) OVER (ORDER BY ca_total DESC)
        WHEN 1 THEN 'Top clients (Q1)'
        WHEN 2 THEN 'Bons clients (Q2)'
        WHEN 3 THEN 'Clients moyens (Q3)'
        WHEN 4 THEN 'Petits clients (Q4)'
    END                                                      AS segment
FROM ca_clients
ORDER BY ca_total DESC;


-- ------------------------------------------------------------
-- 5.2 NTILE(10) : Déciles — distribution fine des commandes
-- ------------------------------------------------------------
SELECT
    order_id,
    order_total,
    NTILE(10) OVER (ORDER BY order_total DESC)               AS decile
FROM co.orders
ORDER BY order_total DESC;


-- ------------------------------------------------------------
-- 5.3 PERCENT_RANK() : Où se situe chaque commande ?
-- Retourne une valeur entre 0.0 et 1.0
-- ------------------------------------------------------------
SELECT
    order_id,
    order_total,
    ROUND(PERCENT_RANK() OVER (ORDER BY order_total) * 100, 1)   AS percentile_rank_pct
FROM co.orders
ORDER BY order_total;


-- ------------------------------------------------------------
-- 5.4 CUME_DIST() : Distribution cumulée
-- "Quelle proportion des commandes est <= ce montant ?"
-- ------------------------------------------------------------
SELECT
    order_id,
    order_total,
    ROUND(CUME_DIST() OVER (ORDER BY order_total) * 100, 1)      AS cume_dist_pct
FROM co.orders
ORDER BY order_total;


-- ------------------------------------------------------------
-- 5.5 Comparaison PERCENT_RANK vs CUME_DIST
-- ------------------------------------------------------------
SELECT
    order_id,
    order_total,
    ROUND(PERCENT_RANK() OVER (ORDER BY order_total) * 100, 1)   AS percent_rank_pct,
    ROUND(CUME_DIST()   OVER (ORDER BY order_total) * 100, 1)    AS cume_dist_pct
FROM co.orders
ORDER BY order_total;


-- ------------------------------------------------------------
-- 5.6 NTILE par catégorie : classer les produits dans leur catégorie
-- ------------------------------------------------------------
SELECT
    category,
    product_name,
    unit_price,
    NTILE(3) OVER (
        PARTITION BY category
        ORDER BY     unit_price DESC
    )                                                        AS tier,
    CASE NTILE(3) OVER (PARTITION BY category ORDER BY unit_price DESC)
        WHEN 1 THEN 'Premium'
        WHEN 2 THEN 'Mid-range'
        WHEN 3 THEN 'Budget'
    END                                                      AS price_tier
FROM co.products
ORDER BY category, unit_price DESC;
