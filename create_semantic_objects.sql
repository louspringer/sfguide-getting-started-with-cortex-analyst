/*
 * Create Semantic Layer Objects
 * Version: 1.0.0
 * 
 * Ontology References:
 * - Primary: @prefix analyst: <./cortex_analyst#>
 * - Objects:
 *   - revenue_model: analyst:RevenueModel
 *   - daily_revenue_measure: analyst:DailyRevenueMeasure
 *   - daily_profit_measure: analyst:DailyProfitMeasure
 *   - date_dimension: analyst:DateDimension
 *
 * Generated from ontology version: 0.1.0
 */

-- Use application role and context
USE ROLE identifier($SNOWFLAKE_ROLE);
USE DATABASE identifier($SNOWFLAKE_DATABASE);
USE SCHEMA identifier($SNOWFLAKE_DATABASE).identifier($SNOWFLAKE_SCHEMA);
USE WAREHOUSE identifier($SNOWFLAKE_WAREHOUSE);

-- Create date dimension table
CREATE OR REPLACE TABLE date_dimension (
    date_key NUMBER NOT NULL,
    full_date DATE NOT NULL,
    year NUMBER,
    quarter NUMBER,
    month NUMBER,
    month_name VARCHAR,
    week NUMBER,
    day_of_week NUMBER,
    day_name VARCHAR,
    is_weekend BOOLEAN,
    is_holiday BOOLEAN,
    fiscal_year NUMBER,
    fiscal_quarter NUMBER,
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_date_dimension PRIMARY KEY (date_key)
);

-- Create measure metadata table
CREATE OR REPLACE TABLE measure_metadata (
    measure_id VARCHAR NOT NULL,
    measure_name VARCHAR NOT NULL,
    description VARCHAR,
    data_type VARCHAR,
    aggregation_type VARCHAR,
    formula VARCHAR,
    is_additive BOOLEAN,
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_measure_metadata PRIMARY KEY (measure_id)
);

-- Create daily revenue measure view
CREATE OR REPLACE VIEW daily_revenue_measure AS
SELECT
    d.date_key,
    d.full_date,
    SUM(t.amount) as daily_revenue,
    COUNT(DISTINCT t.transaction_id) as transaction_count
FROM date_dimension d
LEFT JOIN transactions t ON DATE(t.transaction_date) = d.full_date
GROUP BY d.date_key, d.full_date;

-- Create daily profit measure view
CREATE OR REPLACE VIEW daily_profit_measure AS
SELECT
    d.date_key,
    d.full_date,
    SUM(t.amount - t.cost) as daily_profit,
    SUM(t.amount - t.cost) / NULLIF(SUM(t.amount), 0) as profit_margin
FROM date_dimension d
LEFT JOIN transactions t ON DATE(t.transaction_date) = d.full_date
GROUP BY d.date_key, d.full_date;

-- Create revenue model view
CREATE OR REPLACE VIEW revenue_model AS
SELECT
    d.date_key,
    d.full_date,
    d.year,
    d.quarter,
    d.month,
    d.month_name,
    d.week,
    r.daily_revenue,
    r.transaction_count,
    p.daily_profit,
    p.profit_margin
FROM date_dimension d
LEFT JOIN daily_revenue_measure r ON d.date_key = r.date_key
LEFT JOIN daily_profit_measure p ON d.date_key = p.date_key;

-- Create change tracking triggers
CREATE OR REPLACE TRIGGER trg_date_dimension_update
    BEFORE UPDATE ON date_dimension
    FOR EACH ROW
    EXECUTE AS CALLER
    SET updated_at = CURRENT_TIMESTAMP();

CREATE OR REPLACE TRIGGER trg_measure_metadata_update
    BEFORE UPDATE ON measure_metadata
    FOR EACH ROW
    EXECUTE AS CALLER
    SET updated_at = CURRENT_TIMESTAMP();

-- Insert measure metadata
INSERT INTO measure_metadata (
    measure_id,
    measure_name,
    description,
    data_type,
    aggregation_type,
    formula,
    is_additive
) VALUES
('DAILY_REVENUE', 'Daily Revenue', 'Total revenue per day', 'NUMBER', 'SUM', 'SUM(amount)', true),
('DAILY_PROFIT', 'Daily Profit', 'Total profit per day', 'NUMBER', 'SUM', 'SUM(amount - cost)', true),
('PROFIT_MARGIN', 'Profit Margin', 'Daily profit margin percentage', 'NUMBER', 'NONE', 'SUM(amount - cost) / NULLIF(SUM(amount), 0)', false);

-- Validate object creation
SHOW VIEWS LIKE '%revenue%';
SHOW VIEWS LIKE '%profit%';
SELECT 
    table_name,
    table_type,
    is_transient,
    clustering_key,
    row_count,
    bytes
FROM information_schema.tables
WHERE table_schema = identifier($SNOWFLAKE_SCHEMA)
  AND (table_name LIKE '%DIMENSION%' OR table_name LIKE '%METADATA%')
ORDER BY table_name; 