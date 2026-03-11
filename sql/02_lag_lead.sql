-- ============================================================
-- 02 - COMPARAISON TEMPORELLE
-- LAG() | LEAD()
-- Tables : CO.ORDERS, CO.SHIPMENTS
-- ============================================================


-- ------------------------------------------------------------
-- 2.1 LAG() : Évolution du montant entre commandes d'un client
-- ------------------------------------------------------------
SELECT
    customer_id,
    order_id,
    order_date,
    order_total,
    LAG(order_total) OVER (
        PARTITION BY customer_id
        ORDER BY     order_date
    )                                                        AS commande_precedente,
    order_total - LAG(order_total) OVER (
        PARTITION BY customer_id
        ORDER BY     order_date
    )                                                        AS evolution_montant
FROM co.orders
ORDER BY customer_id, order_date;


-- ------------------------------------------------------------
-- 2.2 LAG() avec valeur par défaut : éviter les NULL
-- LAG(col, offset, valeur_defaut)
-- ------------------------------------------------------------
SELECT
    customer_id,
    order_id,
    order_date,
    order_total,
    LAG(order_total, 1, 0) OVER (
        PARTITION BY customer_id
        ORDER BY     order_date
    )                                                        AS commande_precedente,
    ROUND(
        100.0 * (order_total - LAG(order_total, 1, order_total) OVER (
            PARTITION BY customer_id ORDER BY order_date
        )) / NULLIF(LAG(order_total, 1, order_total) OVER (
            PARTITION BY customer_id ORDER BY order_date
        ), 0),
        1
    )                                                        AS evolution_pct
FROM co.orders
ORDER BY customer_id, order_date;


-- ------------------------------------------------------------
-- 2.3 LEAD() : Délai avant la prochaine expédition
-- ------------------------------------------------------------
SELECT
    order_id,
    shipment_date,
    status,
    LEAD(shipment_date) OVER (
        PARTITION BY order_id
        ORDER BY     shipment_date
    )                                                        AS prochaine_expedition,
    DATEDIFF(
        LEAD(shipment_date) OVER (
            PARTITION BY order_id ORDER BY shipment_date
        ),
        shipment_date
    )                                                        AS jours_entre_expeditions
FROM co.shipments
ORDER BY order_id, shipment_date;


-- ------------------------------------------------------------
-- 2.4 COMBINÉ : Croissance MoM (Month-over-Month) du CA
-- ------------------------------------------------------------
WITH ca_mensuel AS (
    SELECT
        DATE_TRUNC('month', order_date)  AS mois,
        SUM(order_total)                 AS ca
    FROM co.orders
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    mois,
    ca,
    LAG(ca) OVER (ORDER BY mois)              AS ca_mois_precedent,
    ROUND(
        100.0 * (ca - LAG(ca) OVER (ORDER BY mois))
              / NULLIF(LAG(ca) OVER (ORDER BY mois), 0),
        1
    )                                          AS croissance_mom_pct
FROM ca_mensuel
ORDER BY mois;
