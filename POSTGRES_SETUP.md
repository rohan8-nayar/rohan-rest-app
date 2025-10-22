# PostgreSQL Setup Guide

This project has been configured to work with both local development and CI environments.

## Development Setup Options

### Option 1: Docker-only Development (Recommended)
Use Docker Compose for all development work:

```bash
# Start the complete application
make start-api

# Run tests in Docker
docker-compose exec api pytest tests/ -v

# Lint code
docker-compose exec api flake8 *.py tests/
```

### Option 2: Local PostgreSQL + Python
If you prefer local development:

1. **Install PostgreSQL locally:**
   ```bash
   # macOS with Homebrew
   brew install postgresql@14
   brew services start postgresql@14
   
   # Create database
   createdb student_db
   ```

2. **Setup Python environment:**
   ```bash
   make setup  # Uses requirements-dev.txt with psycopg2-binary
   source venv/bin/activate
   python migrate.py
   make test
   ```

## CI/CD Environment

The CI pipeline uses:
- `requirements.txt` with `psycopg2` (compiled from source)
- PostgreSQL service container
- System dependencies for compilation (libpq-dev, gcc)

## Requirements Files

- `requirements.txt` - Production/CI dependencies (uses psycopg2)
- `requirements-dev.txt` - Development dependencies (uses psycopg2-binary)

## Why Different Requirements?

- **psycopg2-binary**: Pre-compiled, easier for local development, may have compatibility issues with newer Python versions
- **psycopg2**: Compiled from source, more reliable in CI/production environments, requires system dependencies