-- ============================================================
-- GlucoCare Commercial Analytics — Database Schema
-- Portable basic SQL (no CTEs / window functions) — tested on
-- MySQL, PostgreSQL, SQL Server, and SQLite.
-- ============================================================

CREATE TABLE territories (
    territory_id                 VARCHAR(10)  PRIMARY KEY,
    territory_name                VARCHAR(50),
    region                         VARCHAR(20),
    population                     INT,
    num_reps_assigned              INT,
    competitor_discount_zone       BOOLEAN,
    reduced_call_intensity_zone    BOOLEAN
);

CREATE TABLE sales_reps (
    rep_id                    VARCHAR(10)  PRIMARY KEY,
    rep_name                  VARCHAR(50),
    territory_id              VARCHAR(10),
    effectiveness_multiplier  DECIMAL(4,2),
    FOREIGN KEY (territory_id) REFERENCES territories(territory_id)
);

CREATE TABLE doctors (
    doctor_id               VARCHAR(10)  PRIMARY KEY,
    doctor_name              VARCHAR(50),
    specialty                 VARCHAR(30),
    territory_id               VARCHAR(10),
    assigned_rep_id            VARCHAR(10),
    years_in_practice          INT,
    patient_volume_monthly     INT,
    baseline_rx_potential      INT,
    loyalty_to_competitor      BOOLEAN,
    is_untapped_target         BOOLEAN,
    defection_month            VARCHAR(7),
    FOREIGN KEY (territory_id) REFERENCES territories(territory_id),
    FOREIGN KEY (assigned_rep_id) REFERENCES sales_reps(rep_id)
);

CREATE TABLE sales_rep_activity (
    rep_id       VARCHAR(10),
    doctor_id     VARCHAR(10),
    month          VARCHAR(7),
    calls_made      INT,
    samples_given    INT,
    FOREIGN KEY (rep_id) REFERENCES sales_reps(rep_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

CREATE TABLE marketing_spend (
    territory_id       VARCHAR(10),
    month                VARCHAR(7),
    digital_spend_inr     DECIMAL(12,2),
    tv_spend_inr           DECIMAL(12,2),
    events_spend_inr        DECIMAL(12,2),
    FOREIGN KEY (territory_id) REFERENCES territories(territory_id)
);

CREATE TABLE competitor_pricing (
    territory_id    VARCHAR(10),
    month             VARCHAR(7),
    drug_name           VARCHAR(20),
    unit_price_inr        DECIMAL(10,2),
    FOREIGN KEY (territory_id) REFERENCES territories(territory_id)
);

CREATE TABLE prescriptions (
    doctor_id       VARCHAR(10),
    territory_id      VARCHAR(10),
    month               VARCHAR(7),
    drug_name             VARCHAR(20),
    prescriptions           INT,
    unit_price_inr            DECIMAL(10,2),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    FOREIGN KEY (territory_id) REFERENCES territories(territory_id)
);
