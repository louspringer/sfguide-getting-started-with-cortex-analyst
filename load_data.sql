/*--
• looad data into tables
--*/

-- Load data for Cortex Analyst demo
-- Requires the following environment variables to be set:
-- SNOWFLAKE_ROLE: Role to be used for deployment
-- SNOWFLAKE_DATABASE: Target database name
-- SNOWFLAKE_SCHEMA: Target schema name
-- SNOWFLAKE_WAREHOUSE: Warehouse to be used
-- SNOWFLAKE_STAGE: Stage name for data files
-- SNOWFLAKE_FILE_FORMAT: Optional file format name (defaults to CSV settings inline)

-- Use application role and context
USE ROLE identifier($SNOWFLAKE_ROLE);
USE DATABASE identifier($SNOWFLAKE_DATABASE);
USE SCHEMA identifier($SNOWFLAKE_DATABASE).identifier($SNOWFLAKE_SCHEMA);
USE WAREHOUSE identifier($SNOWFLAKE_WAREHOUSE);

-- Create file format if not specified
SET FILE_FORMAT_NAME = COALESCE($SNOWFLAKE_FILE_FORMAT, 'CSV_FORMAT');
CREATE FILE FORMAT IF NOT EXISTS identifier($FILE_FORMAT_NAME)
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_DELIMITER = ','
    TRIM_SPACE = FALSE
    FIELD_OPTIONALLY_ENCLOSED_BY = NONE
    REPLACE_INVALID_CHARACTERS = TRUE
    DATE_FORMAT = AUTO
    TIME_FORMAT = AUTO
    TIMESTAMP_FORMAT = AUTO
    EMPTY_FIELD_AS_NULL = FALSE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

-- Load dimension tables first
COPY INTO region_dim
FROM @identifier($SNOWFLAKE_STAGE)
FILES = ('region.csv')
FILE_FORMAT = (FORMAT_NAME = $FILE_FORMAT_NAME)
ON_ERROR = CONTINUE
FORCE = TRUE
VALIDATION_MODE = RETURN_ERRORS;

COPY INTO product_dim
FROM @identifier($SNOWFLAKE_STAGE)
FILES = ('product.csv')
FILE_FORMAT = (FORMAT_NAME = $FILE_FORMAT_NAME)
ON_ERROR = CONTINUE
FORCE = TRUE
VALIDATION_MODE = RETURN_ERRORS;

-- Load fact table
COPY INTO daily_revenue
FROM @identifier($SNOWFLAKE_STAGE)
FILES = ('daily_revenue.csv')
FILE_FORMAT = (FORMAT_NAME = $FILE_FORMAT_NAME)
ON_ERROR = CONTINUE
FORCE = TRUE
VALIDATION_MODE = RETURN_ERRORS;

-- Validate data load
SELECT 
    'daily_revenue' as table_name,
    COUNT(*) as row_count,
    MIN(date) as min_date,
    MAX(date) as max_date,
    SUM(revenue) as total_revenue
FROM daily_revenue
UNION ALL
SELECT 
    'product_dim' as table_name,
    COUNT(*) as row_count,
    NULL as min_date,
    NULL as max_date,
    NULL as total_revenue
FROM product_dim
UNION ALL
SELECT 
    'region_dim' as table_name,
    COUNT(*) as row_count,
    NULL as min_date,
    NULL as max_date,
    NULL as total_revenue
FROM region_dim
ORDER BY table_name;

-- Show any load errors
SELECT *
FROM TABLE(VALIDATE($SNOWFLAKE_DATABASE, $SNOWFLAKE_SCHEMA, 'daily_revenue'));

SELECT *
FROM TABLE(VALIDATE($SNOWFLAKE_DATABASE, $SNOWFLAKE_SCHEMA, 'product_dim'));

SELECT *
FROM TABLE(VALIDATE($SNOWFLAKE_DATABASE, $SNOWFLAKE_SCHEMA, 'region_dim'));