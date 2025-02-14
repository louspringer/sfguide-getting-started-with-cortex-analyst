-- Create schema and required objects for Cortex Analyst demo
-- Requires the following environment variables to be set:
-- SNOWFLAKE_ROLE: Role to be used for deployment
-- SNOWFLAKE_DATABASE: Target database name
-- SNOWFLAKE_SCHEMA: Target schema name
-- SNOWFLAKE_WAREHOUSE: Warehouse to be used
-- SNOWFLAKE_WAREHOUSE_SIZE: Warehouse size (xsmall, small, medium, large)
-- SNOWFLAKE_WAREHOUSE_AUTO_SUSPEND: Auto-suspend timeout in seconds

-- Switch to SECURITYADMIN for role management
USE ROLE SECURITYADMIN;

-- Create role if not exists
CREATE ROLE IF NOT EXISTS identifier($SNOWFLAKE_ROLE);
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE identifier($SNOWFLAKE_ROLE);

-- Switch to SYSADMIN for object creation
USE ROLE SYSADMIN;

-- Create database and schema
CREATE DATABASE IF NOT EXISTS identifier($SNOWFLAKE_DATABASE);
CREATE SCHEMA IF NOT EXISTS identifier($SNOWFLAKE_DATABASE).identifier($SNOWFLAKE_SCHEMA);

-- Create warehouse
CREATE OR REPLACE WAREHOUSE identifier($SNOWFLAKE_WAREHOUSE)
    WAREHOUSE_SIZE = $SNOWFLAKE_WAREHOUSE_SIZE
    WAREHOUSE_TYPE = 'STANDARD'
    AUTO_SUSPEND = $SNOWFLAKE_WAREHOUSE_AUTO_SUSPEND
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
COMMENT = 'Warehouse for Cortex Analyst demo';

-- Grant warehouse access
GRANT USAGE ON WAREHOUSE identifier($SNOWFLAKE_WAREHOUSE) TO ROLE identifier($SNOWFLAKE_ROLE);
GRANT OPERATE ON WAREHOUSE identifier($SNOWFLAKE_WAREHOUSE) TO ROLE identifier($SNOWFLAKE_ROLE);

-- Grant schema access
GRANT OWNERSHIP ON SCHEMA identifier($SNOWFLAKE_DATABASE).identifier($SNOWFLAKE_SCHEMA) 
    TO ROLE identifier($SNOWFLAKE_ROLE);
GRANT OWNERSHIP ON DATABASE identifier($SNOWFLAKE_DATABASE) 
    TO ROLE identifier($SNOWFLAKE_ROLE);

-- Switch to application role
USE ROLE identifier($SNOWFLAKE_ROLE);
USE DATABASE identifier($SNOWFLAKE_DATABASE);
USE SCHEMA identifier($SNOWFLAKE_DATABASE).identifier($SNOWFLAKE_SCHEMA);
USE WAREHOUSE identifier($SNOWFLAKE_WAREHOUSE);

-- Create stage for raw data
CREATE OR REPLACE STAGE raw_data 
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Stage for Cortex Analyst demo data files';

-- Validate setup
SHOW DATABASES LIKE $SNOWFLAKE_DATABASE;
SHOW SCHEMAS LIKE $SNOWFLAKE_SCHEMA;
SHOW WAREHOUSES LIKE $SNOWFLAKE_WAREHOUSE;
SHOW GRANTS TO ROLE identifier($SNOWFLAKE_ROLE); 