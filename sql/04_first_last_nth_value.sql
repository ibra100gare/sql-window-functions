-- ============================================================
-- 04 - VALEURS DE POSITION
-- FIRST_VALUE() | LAST_VALUE() | NTH_VALUE()
-- Tables : CO.ORDERS, CO.PRODUCTS, CO.INVENTORY
-- ============================================================


-- ------------------------------------------------------------
-- 4.1 FIRST_VALUE() : Montant de la 1ère commande de chaque client
-- ⚠️  Sans ROWS BETWEEN, la fenêtre par défaut s'arrête à la ligne courante
-- ------------------------------------------------------------
SELECT
    o.customer_id,
    o.order_id,
    o.order_date,
    o.order_total,
    FIRST_VALUE(o.order_total) OVER (
        PARTITION BY o.customer_id
        ORDER BY     o.order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                                        AS premiere_commande_montant
FROM co.orders o
ORDER BY o.customer_id, o.order_date;


-- ------------------------------------------------------------
-- 4.2 LAST_VALUE() : Dernier statut d'expédition connu
-- ⚠️  TOUJOURS spécifier UNBOUNDED FOLLOWING avec LAST_VALUE
-- ------------------------------------------------------------
SELECT
    order_id,
    shipment_date,
    status,
    LAST_VALUE(status) OVER (
        PARTITION BY order_id
        ORDER BY     shipment_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                                        AS dernier_statut
FROM co.shipments
ORDER BY order_id, shipment_date;


-- ------------------------------------------------------------
-- 4.3 NTH_VALUE() : Montant de la 2ème commande de chaque client
-- ------------------------------------------------------------
SELECT
    customer_id,
    order_id,
    order_date,
    order_total,
    NTH_VALUE(order_total, 2) OVER (
        PARTITION BY customer_id
        ORDER BY     order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                                        AS montant_2eme_commande
FROM co.orders
ORDER BY customer_id, order_date;


-- ------------------------------------------------------------
-- 4.4 Comparer chaque commande à la première (évolution depuis le début)
-- ------------------------------------------------------------
SELECT
    customer_id,
    order_id,
    order_date,
    order_total,
    FIRST_VALUE(order_total) OVER (
        PARTITION BY customer_id
        ORDER BY     order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                                        AS premiere_commande,
    order_total - FIRST_VALUE(order_total) OVER (
        PARTITION BY customer_id
        ORDER BY     order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                                        AS evolution_vs_premiere
FROM co.orders
ORDER BY customer_id, order_date;


-- ------------------------------------------------------------
-- 4.5 Produit le moins cher et le plus cher par catégorie
-- affiché sur chaque ligne de produit
-- ------------------------------------------------------------
SELECT
    category,
    product_name,
    unit_price,
    FIRST_VALUE(product_name) OVER (
        PARTITION BY category
        ORDER BY     unit_price ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                                        AS produit_moins_cher,
    LAST_VALUE(product_name) OVER (
        PARTITION BY category
        ORDER BY     unit_price ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                                        AS produit_plus_cher
FROM co.products
ORDER BY category, unit_price;
