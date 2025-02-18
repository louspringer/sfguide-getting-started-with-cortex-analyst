-- Create schema and required objects for Cortex Analyst demo
-- Requires the following environment variables to be set:
-- SNOWFLAKE_ROLE: Role to be used for deployment
-- SNOWFLAKE_DATABASE: Target database name
-- SNOWFLAKE_SCHEMA: Target schema name
-- SNOWFLAKE_WAREHOUSE: Warehouse to be used
-- SNOWFLAKE_WAREHOUSE_SIZE: Warehouse size (xsmall, small, medium, large)
-- SNOWFLAKE_WAREHOUSE_AUTO_SUSPEND: Auto-suspend timeout in seconds

-- -- Set session variables
-- SET SNOWFLAKE_ROLE = 'cortex_user_role';
-- SET SNOWFLAKE_DATABASE = 'your_database_name';
-- SET SNOWFLAKE_SCHEMA = 'your_schema_name';
-- SET SNOWFLAKE_WAREHOUSE = 'your_warehouse_name';
-- SET SNOWFLAKE_WAREHOUSE_SIZE = 'xsmall';
-- SET SNOWFLAKE_WAREHOUSE_AUTO_SUSPEND = 300;

-- Switch to SECURITYADMIN for role management
USE ROLE SECURITYADMIN;

-- Create role if not exists
CREATE ROLE IF NOT EXISTS identifier('&SNOWFLAKE_ROLE');
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE identifier('&SNOWFLAKE_ROLE');
GRANT ROLE identifier('&SNOWFLAKE_ROLE') TO USER identifier('&SNOWFLAKE_USER');


-- Create warehouse if not exists
USE ROLE ACCOUNTADMIN;
-- Create database if not exists
CREATE DATABASE IF NOT EXISTS identifier('&SNOWFLAKE_DATABASE');
CREATE WAREHOUSE IF NOT EXISTS identifier('&SNOWFLAKE_WAREHOUSE')
    WAREHOUSE_SIZE = &SNOWFLAKE_WAREHOUSE_SIZE
    AUTO_SUSPEND = &SNOWFLAKE_WAREHOUSE_AUTO_SUSPEND
    AUTO_RESUME = TRUE;

-- Create stage
CREATE STAGE IF NOT EXISTS identifier('&SNOWFLAKE_STAGE_NAME')
    FILE_FORMAT = (TYPE = &SNOWFLAKE_FILE_FORMAT);

USE ROLE SYSADMIN;
USE DATABASE identifier('&SNOWFLAKE_DATABASE');
-- Grant permissions
CREATE SCHEMA IF NOT EXISTS identifier('&SNOWFLAKE_SCHEMA');
CREATE SCHEMA IF NOT EXISTS REVENUE_TIMESERIES;
GRANT USAGE ON DATABASE identifier('&SNOWFLAKE_DATABASE') TO ROLE identifier('&SNOWFLAKE_ROLE');
GRANT USAGE ON SCHEMA identifier('&SNOWFLAKE_SCHEMA') TO ROLE identifier('&SNOWFLAKE_ROLE');
GRANT ALL ON WAREHOUSE identifier('&SNOWFLAKE_WAREHOUSE') TO ROLE identifier('&SNOWFLAKE_ROLE');

-- -- Grant schema access
-- GRANT OWNERSHIP ON SCHEMA identifier('&SNOWFLAKE_DATABASE.&SNOWFLAKE_SCHEMA')
--     TO ROLE identifier('&SNOWFLAKE_ROLE');
-- 003036 (23001): SQL execution error: Dependent grant of privilege 'USAGE' on securable 'CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES' to role 'CORTEX_USER_ROLE' exists.  It must be revoked first.  More than one dependent grant may exist: use 'SHOW GRANTS' command to view them.  To revoke all dependent grants while transferring object ownership, use convenience command 'GRANT OWNERSHIP ON <target_objects> TO <target_role> REVOKE CURRENT GRANTS'.

-- GRANT OWNERSHIP ON DATABASE identifier('&SNOWFLAKE_DATABASE') 
--     TO ROLE identifier('&SNOWFLAKE_ROLE');
-- 003036 (23001): SQL execution error: Dependent grant of privilege 'USAGE' on securable 'CORTEX_ANALYST_DEMO' to role 'CORTEX_USER_ROLE' exists.  It must be revoked first.  More than one dependent grant may exist: use 'SHOW GRANTS' command to view them.  To revoke all dependent grants while transferring object ownership, use convenience command 'GRANT OWNERSHIP ON <target_objects> TO <target_role> REVOKE CURRENT GRANTS'.

-- Create stage for raw data
USE ROLE SYSADMIN;
CREATE OR REPLACE STAGE identifier('&SNOWFLAKE_STAGE_NAME') 
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Stage for Cortex Analyst demo data files';

-- Validate setup
SHOW DATABASES LIKE '&SNOWFLAKE_DATABASE';
SHOW SCHEMAS LIKE '&SNOWFLAKE_SCHEMA';
SHOW WAREHOUSES LIKE '&SNOWFLAKE_WAREHOUSE';
SHOW GRANTS TO ROLE identifier('&SNOWFLAKE_ROLE'); 