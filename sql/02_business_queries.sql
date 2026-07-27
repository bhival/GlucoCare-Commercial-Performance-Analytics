-- ============================================================
-- GlucoCare Commercial Analytics — Business Queries
-- Basic SQL only: SELECT, JOIN, GROUP BY, CASE WHEN, subqueries,
-- aggregates. No CTEs or window functions, by design, so these
-- run unmodified on MySQL, PostgreSQL, SQL Server, and SQLite.
-- ============================================================


-- ------------------------------------------------------------
-- Q1. TERRITORY PERFORMANCE RANKING
-- Total GlucoCare prescriptions and revenue by territory,
-- ranked highest to lowest revenue.
-- ------------------------------------------------------------
SELECT
    t.territory_name,
    t.region,
    SUM(p.prescriptions)                           AS total_prescriptions,
    SUM(p.prescriptions * p.unit_price_inr)         AS total_revenue_inr
FROM prescriptions p
JOIN territories t ON p.territory_id = t.territory_id
WHERE p.drug_name = 'GlucoCare'
GROUP BY t.territory_name, t.region
ORDER BY total_revenue_inr DESC;


-- ------------------------------------------------------------
-- Q2. MARKET SHARE % BY TERRITORY
-- GlucoCare prescriptions as a % of all-drug prescriptions,
-- per territory.
-- ------------------------------------------------------------
SELECT
    t.territory_name,
    SUM(CASE WHEN p.drug_name = 'GlucoCare' THEN p.prescriptions ELSE 0 END)           AS glucocare_rx,
    SUM(p.prescriptions)                                                                 AS total_market_rx,
    ROUND(
        100.0 * SUM(CASE WHEN p.drug_name = 'GlucoCare' THEN p.prescriptions ELSE 0 END)
        / SUM(p.prescriptions), 2
    )                                                                                     AS market_share_pct
FROM prescriptions p
JOIN territories t ON p.territory_id = t.territory_id
GROUP BY t.territory_name
ORDER BY market_share_pct DESC;


-- ------------------------------------------------------------
-- Q3. ROOT CAUSE 1 — PRICE GAP DIAGNOSTIC
-- Average GlucoCare price vs. average competitor price by
-- territory, flagging where GlucoCare is priced above the
-- competitor average ("price gap").
-- ------------------------------------------------------------
SELECT
    t.territory_name,
    ROUND(AVG(CASE WHEN cp.drug_name = 'GlucoCare' THEN cp.unit_price_inr END), 2)              AS avg_glucocare_price,
    ROUND(AVG(CASE WHEN cp.drug_name <> 'GlucoCare' THEN cp.unit_price_inr END), 2)              AS avg_competitor_price,
    ROUND(
        AVG(CASE WHEN cp.drug_name = 'GlucoCare' THEN cp.unit_price_inr END)
        - AVG(CASE WHEN cp.drug_name <> 'GlucoCare' THEN cp.unit_price_inr END), 2
    )                                                                                              AS price_gap_inr,
    CASE
        WHEN t.competitor_discount_zone = 1 THEN 'Competitor Discount Zone'
        ELSE 'Standard Zone'
    END                                                                                            AS zone_flag
FROM competitor_pricing cp
JOIN territories t ON cp.territory_id = t.territory_id
GROUP BY t.territory_name, t.competitor_discount_zone
ORDER BY price_gap_inr DESC;


-- ------------------------------------------------------------
-- Q4. ROOT CAUSE 2 — CALL CUTBACK DIAGNOSTIC
-- Average monthly rep calls per doctor, H1 (Jan-Jun) vs.
-- H2 (Jul-Dec), by territory — surfaces the mid-year call
-- intensity cut in the affected zones.
-- ------------------------------------------------------------
SELECT
    t.territory_name,
    ROUND(AVG(CASE WHEN a.month <= '2024-06' THEN a.calls_made END), 2)   AS avg_calls_h1,
    ROUND(AVG(CASE WHEN a.month > '2024-06' THEN a.calls_made END), 2)    AS avg_calls_h2,
    ROUND(
        AVG(CASE WHEN a.month > '2024-06' THEN a.calls_made END)
        - AVG(CASE WHEN a.month <= '2024-06' THEN a.calls_made END), 2
    )                                                                       AS change_in_calls
FROM sales_rep_activity a
JOIN doctors d ON a.doctor_id = d.doctor_id
JOIN territories t ON d.territory_id = t.territory_id
GROUP BY t.territory_name
ORDER BY change_in_calls ASC;


-- ------------------------------------------------------------
-- Q5. ROOT CAUSE 3 — REP EFFECTIVENESS DIAGNOSTIC
-- Prescriptions generated per call made, split by rep
-- effectiveness tier (Low vs. High, via subquery bucketing).
-- ------------------------------------------------------------
SELECT
    rep_tier.effectiveness_tier,
    COUNT(DISTINCT rep_tier.rep_id)                        AS num_reps,
    SUM(rx.total_rx)                                        AS total_prescriptions,
    SUM(act.total_calls)                                    AS total_calls,
    ROUND(SUM(rx.total_rx) * 1.0 / NULLIF(SUM(act.total_calls), 0), 2) AS rx_per_call
FROM (
    SELECT
        rep_id,
        CASE WHEN effectiveness_multiplier < 0.7 THEN 'Low Effectiveness' ELSE 'High Effectiveness' END AS effectiveness_tier
    FROM sales_reps
) rep_tier
JOIN (
    SELECT rep_id, doctor_id, SUM(calls_made) AS total_calls
    FROM sales_rep_activity
    GROUP BY rep_id, doctor_id
) act ON act.rep_id = rep_tier.rep_id
JOIN (
    SELECT d.assigned_rep_id AS rep_id, d.doctor_id, SUM(p.prescriptions) AS total_rx
    FROM prescriptions p
    JOIN doctors d ON p.doctor_id = d.doctor_id
    WHERE p.drug_name = 'GlucoCare'
    GROUP BY d.assigned_rep_id, d.doctor_id
) rx ON rx.rep_id = rep_tier.rep_id AND rx.doctor_id = act.doctor_id
GROUP BY rep_tier.effectiveness_tier;


-- ------------------------------------------------------------
-- Q6. ROOT CAUSE 4 — UNTAPPED HIGH-VALUE DOCTORS
-- Doctors with above-median prescribing potential who receive
-- very few rep calls all year (missed opportunity list).
-- ------------------------------------------------------------
SELECT
    d.doctor_name,
    d.specialty,
    t.territory_name,
    d.baseline_rx_potential,
    calls.total_calls_ytd
FROM doctors d
JOIN territories t ON d.territory_id = t.territory_id
JOIN (
    SELECT doctor_id, SUM(calls_made) AS total_calls_ytd
    FROM sales_rep_activity
    GROUP BY doctor_id
) calls ON calls.doctor_id = d.doctor_id
WHERE d.baseline_rx_potential > (
        SELECT AVG(baseline_rx_potential) FROM doctors
      )
  AND calls.total_calls_ytd < 10
ORDER BY d.baseline_rx_potential DESC;


-- ------------------------------------------------------------
-- Q7. ROOT CAUSE 5 — MARKETING CHANNEL ROI
-- Prescriptions generated per INR 1 lakh spent, by channel,
-- at the territory-month grain.
-- ------------------------------------------------------------
SELECT
    ROUND(SUM(m.digital_spend_inr) / 100000, 2)                                         AS digital_spend_lakh,
    ROUND(SUM(m.tv_spend_inr) / 100000, 2)                                               AS tv_spend_lakh,
    ROUND(SUM(m.events_spend_inr) / 100000, 2)                                           AS events_spend_lakh,
    SUM(rx.glucocare_rx)                                                                   AS total_glucocare_rx,
    ROUND(SUM(rx.glucocare_rx) / NULLIF(SUM(m.digital_spend_inr) / 100000, 0), 2)          AS rx_per_lakh_digital_proxy,
    ROUND(SUM(rx.glucocare_rx) / NULLIF(SUM(m.tv_spend_inr) / 100000, 0), 2)               AS rx_per_lakh_tv_proxy
FROM marketing_spend m
JOIN (
    SELECT territory_id, month, SUM(prescriptions) AS glucocare_rx
    FROM prescriptions
    WHERE drug_name = 'GlucoCare'
    GROUP BY territory_id, month
) rx ON rx.territory_id = m.territory_id AND rx.month = m.month;


-- ------------------------------------------------------------
-- Q8. PRESCRIBER SEGMENTATION
-- Buckets every doctor into a commercial segment using
-- CASE WHEN logic on the ground-truth flags.
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN d.defection_month IS NOT NULL AND d.defection_month <> '' THEN 'Lost (Defected)'
        WHEN d.is_untapped_target = 1 THEN 'Untapped High-Value'
        WHEN d.loyalty_to_competitor = 1 THEN 'Competitor Loyalist'
        ELSE 'Core GlucoCare Prescriber'
    END                        AS segment,
    COUNT(*)                    AS num_doctors,
    ROUND(AVG(d.baseline_rx_potential), 1) AS avg_rx_potential
FROM doctors d
GROUP BY
    CASE
        WHEN d.defection_month IS NOT NULL AND d.defection_month <> '' THEN 'Lost (Defected)'
        WHEN d.is_untapped_target = 1 THEN 'Untapped High-Value'
        WHEN d.loyalty_to_competitor = 1 THEN 'Competitor Loyalist'
        ELSE 'Core GlucoCare Prescriber'
    END
ORDER BY num_doctors DESC;


-- ------------------------------------------------------------
-- Q9. H1 vs. H2 REGIONAL SCORECARD
-- GlucoCare prescriptions by region, first half vs. second
-- half of 2024, with % change.
-- ------------------------------------------------------------
SELECT
    t.region,
    SUM(CASE WHEN p.month <= '2024-06' THEN p.prescriptions ELSE 0 END)   AS h1_prescriptions,
    SUM(CASE WHEN p.month > '2024-06' THEN p.prescriptions ELSE 0 END)    AS h2_prescriptions,
    ROUND(
        100.0 * (
            SUM(CASE WHEN p.month > '2024-06' THEN p.prescriptions ELSE 0 END)
            - SUM(CASE WHEN p.month <= '2024-06' THEN p.prescriptions ELSE 0 END)
        ) / NULLIF(SUM(CASE WHEN p.month <= '2024-06' THEN p.prescriptions ELSE 0 END), 0), 2
    )                                                                       AS pct_change_h1_to_h2
FROM prescriptions p
JOIN territories t ON p.territory_id = t.territory_id
WHERE p.drug_name = 'GlucoCare'
GROUP BY t.region
ORDER BY pct_change_h1_to_h2 ASC;


-- ------------------------------------------------------------
-- Q10. TOP 10 DOCTORS BY GLUCOCARE REVENUE
-- Highest-value prescribers, useful for account prioritization.
-- ------------------------------------------------------------
SELECT
    d.doctor_name,
    d.specialty,
    t.territory_name,
    SUM(p.prescriptions)                       AS total_prescriptions,
    SUM(p.prescriptions * p.unit_price_inr)     AS total_revenue_inr
FROM prescriptions p
JOIN doctors d ON p.doctor_id = d.doctor_id
JOIN territories t ON d.territory_id = t.territory_id
WHERE p.drug_name = 'GlucoCare'
GROUP BY d.doctor_name, d.specialty, t.territory_name
ORDER BY total_revenue_inr DESC
LIMIT 10;
