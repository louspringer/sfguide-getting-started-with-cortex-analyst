#!/bin/bash

# Exit on error
set -e

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Load environment variables
if [ -f ../.env ]; then
    source ../.env
else
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please copy .env.template to .env and fill in the values"
    exit 1
fi

# Required environment variables
required_vars=(
    "SNOWFLAKE_ROLE"
    "SNOWFLAKE_DATABASE"
    "SNOWFLAKE_SCHEMA"
    "SNOWFLAKE_WAREHOUSE"
    "SNOWFLAKE_WAREHOUSE_SIZE"
    "SNOWFLAKE_WAREHOUSE_AUTO_SUSPEND"
    "SNOWFLAKE_STAGE"
)

# Check for missing variables
missing_vars=()
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo -e "${RED}Error: Missing required environment variables:${NC}"
    printf '%s\n' "${missing_vars[@]}"
    exit 1
fi

# Function to run SQL script with error handling
run_sql_script() {
    local script=$1
    local description=$2
    
    echo -e "${YELLOW}Running $description...${NC}"
    
    if snowsql -f "$script"; then
        echo -e "${GREEN}✓ $description completed successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ $description failed${NC}"
        return 1
    fi
}

# Main deployment process
echo "Starting Cortex Analyst deployment..."

# Step 1: Create schema and infrastructure
echo -e "\n${YELLOW}Step 1: Creating Infrastructure${NC}"
run_sql_script "$SCRIPT_DIR/create_schema.sql" "schema and infrastructure creation" || exit 1

# Step 2: Create base Cortex Analyst tables
echo -e "\n${YELLOW}Step 2: Creating Base Cortex Analyst Tables${NC}"
run_sql_script "$SCRIPT_DIR/create_tables.sql" "base table creation" || exit 1

# Step 3: Create Teams integration tables
echo -e "\n${YELLOW}Step 3: Creating Teams Integration Tables${NC}"
run_sql_script "$SCRIPT_DIR/create_teams_tables.sql" "Teams tables creation" || exit 1

# Step 4: Create semantic layer objects
echo -e "\n${YELLOW}Step 4: Creating Semantic Layer Objects${NC}"
run_sql_script "$SCRIPT_DIR/create_semantic_objects.sql" "semantic objects creation" || exit 1

# Step 5: Load data
echo -e "\n${YELLOW}Step 5: Loading Data${NC}"
# Check if data files exist in stage
echo -e "${YELLOW}Checking for data files in stage $SNOWFLAKE_STAGE...${NC}"
snowsql -q "LIST @$SNOWFLAKE_STAGE" || {
    echo -e "${RED}Error: Could not access stage or no files found${NC}"
    exit 1
}

run_sql_script "$SCRIPT_DIR/load_data.sql" "data loading" || exit 1

echo -e "${GREEN}Deployment completed successfully!${NC}"

# Show deployment summary
echo -e "\nDeployment Summary:"
echo -e "==================="
echo -e "Database: ${YELLOW}$SNOWFLAKE_DATABASE${NC}"
echo -e "Schema: ${YELLOW}$SNOWFLAKE_SCHEMA${NC}"
echo -e "Role: ${YELLOW}$SNOWFLAKE_ROLE${NC}"
echo -e "Warehouse: ${YELLOW}$SNOWFLAKE_WAREHOUSE${NC}"

# Validate deployment
echo -e "\nValidating deployment..."
echo -e "\n${YELLOW}Base Tables:${NC}"
snowsql -q "
    SELECT 
        table_name,
        row_count
    FROM ${SNOWFLAKE_DATABASE}.information_schema.tables
    WHERE table_schema = '${SNOWFLAKE_SCHEMA}'
    AND table_type = 'BASE TABLE'
    AND table_name NOT LIKE 'TEAMS_%'
    AND table_name NOT LIKE 'BOT_%'
    ORDER BY table_name;
"

echo -e "\n${YELLOW}Teams Integration Tables:${NC}"
snowsql -q "
    SELECT 
        table_name,
        row_count
    FROM ${SNOWFLAKE_DATABASE}.information_schema.tables
    WHERE table_schema = '${SNOWFLAKE_SCHEMA}'
    AND table_type = 'BASE TABLE'
    AND (table_name LIKE 'TEAMS_%' OR table_name LIKE 'BOT_%')
    ORDER BY table_name;
"

echo -e "\n${YELLOW}Semantic Layer Objects:${NC}"
snowsql -q "
    SELECT 
        table_name,
        view_definition
    FROM ${SNOWFLAKE_DATABASE}.information_schema.views
    WHERE table_schema = '${SNOWFLAKE_SCHEMA}'
    ORDER BY table_name;
"

echo -e "\n${GREEN}✓ Deployment validation complete${NC}" 