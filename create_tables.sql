/*
 * Create tables for Cortex Analyst demo
 * Version: 1.0.0
 * 
 * Ontology References:
 * - Primary: @prefix ca: <./cortex_analyst#>
 * - Tables:
 *   - daily_revenue: ca:DailyRevenueTable
 *   - product_dim: ca:ProductDimTable
 *   - region_dim: ca:RegionDimTable
 *
 * Generated from ontology version: 0.1.0
 */

-- Create tables for Cortex Analyst demo
-- Requires the following environment variables to be set:
-- SNOWFLAKE_ROLE: Role to be used for deployment
-- SNOWFLAKE_DATABASE: Target database name
-- SNOWFLAKE_SCHEMA: Target schema name
-- SNOWFLAKE_WAREHOUSE: Warehouse to be used

-- Use application role and context
USE ROLE identifier($SNOWFLAKE_ROLE);
USE DATABASE identifier($SNOWFLAKE_DATABASE);
USE SCHEMA identifier($SNOWFLAKE_DATABASE).identifier($SNOWFLAKE_SCHEMA);
USE WAREHOUSE identifier($SNOWFLAKE_WAREHOUSE);

-- Fact table: daily_revenue
CREATE OR REPLACE TABLE daily_revenue (
    date DATE,
    revenue FLOAT,
    cogs FLOAT,
    forecasted_revenue FLOAT,
    product_id INT,
    region_id INT,
    
    -- Metadata
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- Constraints
    CONSTRAINT pk_daily_revenue PRIMARY KEY (date, product_id, region_id),
    CONSTRAINT chk_revenue_positive CHECK (revenue >= 0),
    CONSTRAINT chk_cogs_positive CHECK (cogs >= 0)
)
COMMENT = 'Daily revenue fact table for Cortex Analyst demo';

-- Dimension table: product_dim
CREATE OR REPLACE TABLE product_dim (
    product_id INT,
    product_line VARCHAR(16777216),
    
    -- Metadata
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- Constraints
    CONSTRAINT pk_product PRIMARY KEY (product_id)
)
COMMENT = 'Product dimension table for Cortex Analyst demo';

-- Dimension table: region_dim
CREATE OR REPLACE TABLE region_dim (
    region_id INT,
    sales_region VARCHAR(16777216),
    state VARCHAR(16777216),
    
    -- Metadata
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- Constraints
    CONSTRAINT pk_region PRIMARY KEY (region_id)
)
COMMENT = 'Region dimension table for Cortex Analyst demo';

-- Add foreign key constraints
ALTER TABLE daily_revenue
    ADD CONSTRAINT fk_daily_revenue_product 
    FOREIGN KEY (product_id) REFERENCES product_dim(product_id);

ALTER TABLE daily_revenue
    ADD CONSTRAINT fk_daily_revenue_region
    FOREIGN KEY (region_id) REFERENCES region_dim(region_id);

-- Create change tracking triggers
CREATE OR REPLACE TRIGGER trg_daily_revenue_update
    BEFORE UPDATE ON daily_revenue
    FOR EACH ROW
    EXECUTE AS CALLER
    SET updated_at = CURRENT_TIMESTAMP();

CREATE OR REPLACE TRIGGER trg_product_dim_update
    BEFORE UPDATE ON product_dim
    FOR EACH ROW
    EXECUTE AS CALLER
    SET updated_at = CURRENT_TIMESTAMP();

CREATE OR REPLACE TRIGGER trg_region_dim_update
    BEFORE UPDATE ON region_dim
    FOR EACH ROW
    EXECUTE AS CALLER
    SET updated_at = CURRENT_TIMESTAMP();

-- Validate table creation
SHOW TABLES LIKE '%';
SELECT 
    table_name,
    table_type,
    is_transient,
    clustering_key,
    row_count,
    bytes
FROM information_schema.tables
WHERE table_schema = identifier($SNOWFLAKE_SCHEMA)
ORDER BY table_name; 