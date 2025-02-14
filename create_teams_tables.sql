/*
 * Create Teams integration tables
 * Version: 1.0.0
 * 
 * Ontology References:
 * - Primary: @prefix teams: <./cortexteams#>
 * - Tables:
 *   - teams_tenant: teams:TeamsTenantTable
 *   - teams_user: teams:TeamsUserTable
 *   - teams_conversation: teams:TeamsConversationTable
 *   - teams_meeting: teams:TeamsMeetingTable
 *   - teams_token_store: teams:TeamsTokenStoreTable
 *   - bot_interaction_log: teams:BotInteractionLogTable
 *   - bot_state: teams:BotStateTable
 *
 * Generated from ontology version: 0.1.0
 */

-- Use application role and context
USE ROLE identifier($SNOWFLAKE_ROLE);
USE DATABASE identifier($SNOWFLAKE_DATABASE);
USE SCHEMA identifier($SNOWFLAKE_DATABASE).identifier($SNOWFLAKE_SCHEMA);
USE WAREHOUSE identifier($SNOWFLAKE_WAREHOUSE);

-- Create Teams tenant table
CREATE OR REPLACE TABLE teams_tenant (
    tenant_id VARCHAR NOT NULL,
    name VARCHAR,
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_teams_tenant PRIMARY KEY (tenant_id)
);

-- Create Teams user table
CREATE OR REPLACE TABLE teams_user (
    user_id VARCHAR NOT NULL,
    tenant_id VARCHAR NOT NULL,
    name VARCHAR,
    email VARCHAR,
    given_name VARCHAR,
    surname VARCHAR,
    user_principal_name VARCHAR,
    aad_object_id VARCHAR,
    user_role VARCHAR,
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_teams_user PRIMARY KEY (user_id),
    CONSTRAINT fk_teams_user_tenant FOREIGN KEY (tenant_id) 
        REFERENCES teams_tenant(tenant_id)
);

-- Create Teams conversation table
CREATE OR REPLACE TABLE teams_conversation (
    conversation_id VARCHAR NOT NULL,
    tenant_id VARCHAR NOT NULL,
    channel_id VARCHAR,
    team_id VARCHAR,
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_teams_conversation PRIMARY KEY (conversation_id),
    CONSTRAINT fk_teams_conversation_tenant FOREIGN KEY (tenant_id) 
        REFERENCES teams_tenant(tenant_id)
);

-- Create Teams meeting table
CREATE OR REPLACE TABLE teams_meeting (
    meeting_id VARCHAR NOT NULL,
    tenant_id VARCHAR NOT NULL,
    organizer_id VARCHAR NOT NULL,
    start_time TIMESTAMP_LTZ,
    end_time TIMESTAMP_LTZ,
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_teams_meeting PRIMARY KEY (meeting_id),
    CONSTRAINT fk_teams_meeting_tenant FOREIGN KEY (tenant_id) 
        REFERENCES teams_tenant(tenant_id),
    CONSTRAINT fk_teams_meeting_organizer FOREIGN KEY (organizer_id) 
        REFERENCES teams_user(user_id)
);

-- Create Teams token store table
CREATE OR REPLACE TABLE teams_token_store (
    token_id VARCHAR NOT NULL,
    user_id VARCHAR NOT NULL,
    tenant_id VARCHAR NOT NULL,
    token VARCHAR,
    expires_at TIMESTAMP_LTZ,
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_teams_token_store PRIMARY KEY (token_id),
    CONSTRAINT fk_teams_token_user FOREIGN KEY (user_id) 
        REFERENCES teams_user(user_id),
    CONSTRAINT fk_teams_token_tenant FOREIGN KEY (tenant_id) 
        REFERENCES teams_tenant(tenant_id)
);

-- Create bot interaction log table
CREATE OR REPLACE TABLE bot_interaction_log (
    interaction_id VARCHAR NOT NULL,
    user_id VARCHAR NOT NULL,
    tenant_id VARCHAR NOT NULL,
    conversation_id VARCHAR NOT NULL,
    interaction_type VARCHAR,
    query_text VARCHAR,
    response_text VARCHAR,
    error_message VARCHAR,
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_bot_interaction_log PRIMARY KEY (interaction_id),
    CONSTRAINT fk_bot_interaction_user FOREIGN KEY (user_id) 
        REFERENCES teams_user(user_id),
    CONSTRAINT fk_bot_interaction_tenant FOREIGN KEY (tenant_id) 
        REFERENCES teams_tenant(tenant_id),
    CONSTRAINT fk_bot_interaction_conversation FOREIGN KEY (conversation_id) 
        REFERENCES teams_conversation(conversation_id)
);

-- Create bot state table
CREATE OR REPLACE TABLE bot_state (
    state_id VARCHAR NOT NULL,
    user_id VARCHAR NOT NULL,
    conversation_id VARCHAR NOT NULL,
    state_data VARIANT,
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    CONSTRAINT pk_bot_state PRIMARY KEY (state_id),
    CONSTRAINT fk_bot_state_user FOREIGN KEY (user_id) 
        REFERENCES teams_user(user_id),
    CONSTRAINT fk_bot_state_conversation FOREIGN KEY (conversation_id) 
        REFERENCES teams_conversation(conversation_id)
);

-- Create bot interaction metrics view
CREATE OR REPLACE VIEW bot_interaction_metrics AS
SELECT
    DATE_TRUNC('day', created_at) as interaction_date,
    COUNT(*) as daily_interactions,
    SUM(CASE WHEN error_message IS NOT NULL THEN 1 ELSE 0 END)::FLOAT / 
        COUNT(*)::FLOAT as error_rate
FROM bot_interaction_log
GROUP BY interaction_date;

-- Create change tracking triggers
CREATE OR REPLACE TRIGGER trg_teams_tenant_update
    BEFORE UPDATE ON teams_tenant
    FOR EACH ROW
    EXECUTE AS CALLER
    SET updated_at = CURRENT_TIMESTAMP();

CREATE OR REPLACE TRIGGER trg_teams_user_update
    BEFORE UPDATE ON teams_user
    FOR EACH ROW
    EXECUTE AS CALLER
    SET updated_at = CURRENT_TIMESTAMP();

CREATE OR REPLACE TRIGGER trg_teams_conversation_update
    BEFORE UPDATE ON teams_conversation
    FOR EACH ROW
    EXECUTE AS CALLER
    SET updated_at = CURRENT_TIMESTAMP();

CREATE OR REPLACE TRIGGER trg_teams_meeting_update
    BEFORE UPDATE ON teams_meeting
    FOR EACH ROW
    EXECUTE AS CALLER
    SET updated_at = CURRENT_TIMESTAMP();

CREATE OR REPLACE TRIGGER trg_teams_token_store_update
    BEFORE UPDATE ON teams_token_store
    FOR EACH ROW
    EXECUTE AS CALLER
    SET updated_at = CURRENT_TIMESTAMP();

CREATE OR REPLACE TRIGGER trg_bot_state_update
    BEFORE UPDATE ON bot_state
    FOR EACH ROW
    EXECUTE AS CALLER
    SET updated_at = CURRENT_TIMESTAMP();

-- Validate table creation
SHOW TABLES LIKE '%teams%';
SHOW TABLES LIKE '%bot%';
SELECT 
    table_name,
    table_type,
    is_transient,
    clustering_key,
    row_count,
    bytes
FROM information_schema.tables
WHERE table_schema = identifier($SNOWFLAKE_SCHEMA)
  AND (table_name LIKE '%TEAMS%' OR table_name LIKE '%BOT%')
ORDER BY table_name; 