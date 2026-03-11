-- ============================================================
-- 01 - FONCTIONS DE CLASSEMENT
-- ROW_NUMBER() | RANK() | DENSE_RANK()
-- Tables : CO.ORDERS, CO.ORDER_ITEMS, CO.PRODUCTS
-- ============================================================


-- ------------------------------------------------------------
-- 1.1 ROW_NUMBER() : Numéroter les commandes de chaque client
-- ------------------------------------------------------------
SELECT
    o.customer_id,
    o.order_id,
    o.order_date,
    o.order_total,
    ROW_NUMBER() OVER (
        PARTITION BY o.customer_id
        ORDER BY     o.order_date ASC
    ) AS num_commande
FROM co.orders o
ORDER BY o.customer_id, o.order_date;


-- ------------------------------------------------------------
-- 1.2 RANK() vs DENSE_RANK() : Classer les produits par CA
-- ------------------------------------------------------------
SELECT
    p.product_name,
    SUM(oi.unit_price * oi.quantity)                                              AS ca_total,
    RANK()       OVER (ORDER BY SUM(oi.unit_price * oi.quantity) DESC)           AS rank_std,
    DENSE_RANK() OVER (ORDER BY SUM(oi.unit_price * oi.quantity) DESC)           AS rank_dense
FROM co.order_items oi
JOIN co.products    p  ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY ca_total DESC;


-- ------------------------------------------------------------
-- 1.3 TOP-N PAR GROUPE : Top 2 produits par catégorie
-- Pattern classique avec CTE + RANK()
-- ------------------------------------------------------------
WITH ranked_products AS (
    SELECT
        p.category,
        p.product_name,
        SUM(oi.unit_price * oi.quantity)  AS ca,
        RANK() OVER (
            PARTITION BY p.category
            ORDER BY SUM(oi.unit_price * oi.quantity) DESC
        ) AS rang
    FROM co.order_items oi
    JOIN co.products    p ON p.product_id = oi.product_id
    GROUP BY p.category, p.product_name
)
SELECT category, product_name, ca, rang
FROM   ranked_products
WHERE  rang <= 2
ORDER BY category, rang;


-- ------------------------------------------------------------
-- 1.4 BONUS : Dédupliquer — garder la dernière commande par client
-- ------------------------------------------------------------
WITH derniere_commande AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY     order_date DESC
        ) AS rn
    FROM co.orders
)
SELECT customer_id, order_id, order_date, order_total
FROM   derniere_commande
WHERE  rn = 1;
