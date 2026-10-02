-- ============================================================
-- BLUESTOCK MF - DAY 2 ANALYTICAL QUERIES
-- ============================================================


-- ============================================================
-- 1. TOP 5 FUNDS BY AUM
--
-- Scheme-level AUM comes from 07_scheme_performance.csv.
-- It is stored in fact_performance.aum_crore.
-- ============================================================

SELECT
    f.amfi_code,
    f.scheme_name,
    p.aum_crore
FROM fact_performance p
JOIN dim_fund f
    ON p.amfi_code = f.amfi_code
WHERE p.aum_crore IS NOT NULL
ORDER BY p.aum_crore DESC
LIMIT 5;


-- ============================================================
-- 2. AVERAGE NAV PER MONTH
-- ============================================================

SELECT
    f.amfi_code,
    f.scheme_name,
    strftime('%Y-%m', n.date_id) AS month,
    ROUND(AVG(n.nav), 4) AS average_nav
FROM fact_nav n
JOIN dim_fund f
    ON f.amfi_code = n.amfi_code
GROUP BY
    f.amfi_code,
    f.scheme_name,
    month
ORDER BY
    f.amfi_code,
    month;


-- ============================================================
-- 3. SIP YEAR-OVER-YEAR GROWTH
-- ============================================================

WITH sip_by_year AS (

    SELECT
        strftime('%Y', date_id) AS year,
        SUM(amount) AS total_sip
    FROM fact_transactions
    WHERE transaction_type = 'SIP'
    GROUP BY year
),

sip_with_previous AS (

    SELECT
        year,
        total_sip,
        LAG(total_sip)
            OVER (ORDER BY year) AS previous_year_sip
    FROM sip_by_year
)

SELECT
    year,
    ROUND(total_sip, 2) AS total_sip,
    ROUND(previous_year_sip, 2) AS previous_year_sip,

    CASE
        WHEN previous_year_sip IS NULL
             OR previous_year_sip = 0
        THEN NULL

        ELSE ROUND(
            100.0 *
            (total_sip - previous_year_sip)
            / previous_year_sip,
            2
        )
    END AS yoy_growth_pct

FROM sip_with_previous
ORDER BY year;


-- ============================================================
-- 4. TRANSACTIONS BY STATE
-- ============================================================

SELECT
    i.state,
    COUNT(*) AS transaction_count,
    ROUND(SUM(t.amount), 2) AS total_amount
FROM fact_transactions t
JOIN dim_investor i
    ON i.investor_id = t.investor_id
GROUP BY i.state
ORDER BY total_amount DESC;


-- ============================================================
-- 5. FUNDS WITH EXPENSE RATIO < 1%
-- ============================================================

SELECT
    f.amfi_code,
    f.scheme_name,
    p.expense_ratio
FROM fact_performance p
JOIN dim_fund f
    ON f.amfi_code = p.amfi_code
WHERE p.expense_ratio < 1.0
ORDER BY p.expense_ratio ASC;


-- ============================================================
-- 6. REDEMPTION-TO-INFLOW RATIO BY FUND
-- ============================================================

SELECT
    f.amfi_code,
    f.scheme_name,

    SUM(
        CASE
            WHEN t.transaction_type = 'Redemption'
            THEN t.amount
            ELSE 0
        END
    ) AS total_redemptions,

    SUM(
        CASE
            WHEN t.transaction_type IN ('SIP', 'Lumpsum')
            THEN t.amount
            ELSE 0
        END
    ) AS total_inflows,

    ROUND(
        SUM(
            CASE
                WHEN t.transaction_type = 'Redemption'
                THEN t.amount
                ELSE 0
            END
        ) * 1.0
        /
        NULLIF(
            SUM(
                CASE
                    WHEN t.transaction_type IN ('SIP', 'Lumpsum')
                    THEN t.amount
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS redemption_to_inflow_ratio

FROM fact_transactions t
JOIN dim_fund f
    ON f.amfi_code = t.amfi_code

GROUP BY
    f.amfi_code,
    f.scheme_name

ORDER BY redemption_to_inflow_ratio DESC;


-- ============================================================
-- 7. FUNDS BY 1-YEAR RETURN
-- ============================================================

SELECT
    f.amfi_code,
    f.scheme_name,
    p.return_1y
FROM fact_performance p
JOIN dim_fund f
    ON f.amfi_code = p.amfi_code
WHERE p.return_1y IS NOT NULL
ORDER BY p.return_1y DESC
LIMIT 5;


-- ============================================================
-- 8. MONTHLY SIP COUNT AND AVERAGE TICKET SIZE
-- ============================================================

SELECT
    strftime('%Y-%m', date_id) AS month,
    COUNT(*) AS sip_count,
    ROUND(AVG(amount), 2) AS average_sip_amount,
    ROUND(SUM(amount), 2) AS total_sip_amount
FROM fact_transactions
WHERE transaction_type = 'SIP'
GROUP BY month
ORDER BY month;


-- ============================================================
-- 9. KYC STATUS DISTRIBUTION
-- ============================================================

SELECT
    i.kyc_status,
    COUNT(DISTINCT i.investor_id) AS investor_count
FROM dim_investor i
JOIN fact_transactions t
    ON t.investor_id = i.investor_id
GROUP BY i.kyc_status
ORDER BY investor_count DESC;


-- ============================================================
-- 10. NAV RANGE PER FUND
-- ============================================================

SELECT
    f.amfi_code,
    f.scheme_name,

    MIN(n.nav) AS minimum_nav,
    MAX(n.nav) AS maximum_nav,

    ROUND(
        MAX(n.nav) - MIN(n.nav),
        4
    ) AS nav_range,

    ROUND(
        (
            MAX(n.nav) - MIN(n.nav)
        )
        /
        NULLIF(MIN(n.nav), 0)
        * 100,
        2
    ) AS range_pct_of_min

FROM fact_nav n
JOIN dim_fund f
    ON f.amfi_code = n.amfi_code

GROUP BY
    f.amfi_code,
    f.scheme_name

ORDER BY range_pct_of_min DESC;
