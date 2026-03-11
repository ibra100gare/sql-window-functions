-- ============================================================
-- 03 - AGRÉGATS GLISSANTS
-- SUM() OVER | AVG() OVER | COUNT() OVER | MIN/MAX() OVER
-- Tables : CO.ORDERS, CO.STORES
-- ============================================================


-- ------------------------------------------------------------
-- 3.1 Running Total : CA cumulé dans le temps
-- ------------------------------------------------------------
SELECT
    DATE_TRUNC('month', order_date)                          AS mois,
    SUM(order_total)                                         AS ca_mensuel,
    SUM(SUM(order_total)) OVER (
        ORDER BY DATE_TRUNC('month', order_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                        AS ca_cumule
FROM co.orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY mois;


-- ------------------------------------------------------------
-- 3.2 Moyenne mobile sur 3 mois glissants
-- ------------------------------------------------------------
SELECT
    DATE_TRUNC('month', order_date)                          AS mois,
    SUM(order_total)                                         AS ca_mensuel,
    ROUND(
        AVG(SUM(order_total)) OVER (
            ORDER BY DATE_TRUNC('month', order_date)
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    )                                                        AS moy_mobile_3mois
FROM co.orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY mois;


-- ------------------------------------------------------------
-- 3.3 Part du total : % CA par magasin
-- OVER () sans PARTITION = toute la table
-- ------------------------------------------------------------
SELECT
    s.store_name,
    SUM(o.order_total)                                       AS ca_store,
    SUM(SUM(o.order_total)) OVER ()                          AS ca_global,
    ROUND(
        100.0 * SUM(o.order_total)
              / SUM(SUM(o.order_total)) OVER (),
        2
    )                                                        AS pct_ca
FROM co.orders   o
JOIN co.stores   s ON s.store_id = o.store_id
GROUP BY s.store_name
ORDER BY ca_store DESC;


-- ------------------------------------------------------------
-- 3.4 Running Count : nombre cumulé de commandes par client
-- ------------------------------------------------------------
SELECT
    customer_id,
    order_id,
    order_date,
    COUNT(*) OVER (
        PARTITION BY customer_id
        ORDER BY     order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                        AS nb_commandes_cumule
FROM co.orders
ORDER BY customer_id, order_date;


-- ------------------------------------------------------------
-- 3.5 MIN / MAX glissants : prix min/max des produits vus
-- ------------------------------------------------------------
SELECT
    customer_id,
    order_id,
    order_date,
    order_total,
    MIN(order_total) OVER (
        PARTITION BY customer_id
        ORDER BY     order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                        AS min_commande_client,
    MAX(order_total) OVER (
        PARTITION BY customer_id
        ORDER BY     order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                        AS max_commande_client
FROM co.orders
ORDER BY customer_id, order_date;


-- ------------------------------------------------------------
-- 3.6 Comparaison à la moyenne de la catégorie
-- ------------------------------------------------------------
SELECT
    p.category,
    p.product_name,
    p.unit_price,
    ROUND(
        AVG(p.unit_price) OVER (PARTITION BY p.category),
        2
    )                                                        AS moy_prix_categorie,
    ROUND(
        p.unit_price - AVG(p.unit_price) OVER (PARTITION BY p.category),
        2
    )                                                        AS ecart_a_la_moyenne
FROM co.products p
ORDER BY p.category, p.unit_price DESC;
