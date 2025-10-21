-- Initial database setup for Student CRUD API
-- This script runs when the PostgreSQL container starts for the first time

-- Create database if it doesn't exist (handled by POSTGRES_DB env var)
-- The database is automatically created by the postgres container

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Set timezone
SET timezone = 'UTC';

-- Log that initialization is complete
SELECT 'Database initialization completed' AS status;