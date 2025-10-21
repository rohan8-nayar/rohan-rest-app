# Student CRUD REST API

A complete REST API for managing student records built with Python Flask, following REST best practices and the Twelve-Factor App methodology.

## Features

- **Full CRUD Operations**: Create, Read, Update, Delete students
- **RESTful Design**: Proper HTTP verbs and status codes
- **API Versioning**: `/api/v1/` prefix for future compatibility
- **Database Integration**: PostgreSQL with SQLAlchemy ORM
- **Environment Configuration**: 12-factor app compliance with environment variables
- **Comprehensive Logging**: Structured logging with different levels
- **Health Check Endpoint**: Monitor API status
- **Input Validation**: Proper request validation and error handling
- **Pagination**: Efficient data retrieval for large datasets
- **Unit Tests**: Comprehensive test coverage
- **Makefile**: Easy build and deployment commands

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/healthcheck` | Health check endpoint |
| `POST` | `/api/v1/students` | Create a new student |
| `GET` | `/api/v1/students` | Get all students (paginated) |
| `GET` | `/api/v1/students/{id}` | Get student by ID |
| `PUT` | `/api/v1/students/{id}` | Update student by ID |
| `DELETE` | `/api/v1/students/{id}` | Delete student by ID |

## Student Data Model

```json
{
  "id": 1,
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "age": 20,
  "grade": "A",
  "enrollment_date": "2024-01-15T10:30:00",
  "created_at": "2024-01-15T10:30:00",
  "updated_at": "2024-01-15T10:30:00"
}
```

## Prerequisites

- **Docker 20.10+** (required for containerization)
- **Docker Compose 2.0+** (required for multi-service orchestration)  
- **Make** (required for using Makefile targets)
- **Git** (required for version tagging)
- Python 3.8+ (optional, for local development without Docker)
- pip (optional, for local development without Docker)

## Docker Compose Setup Instructions (Recommended)

### Quick Start

```bash
# Complete setup and start all services
make start-api

# This automatically:
# 1. Starts PostgreSQL database
# 2. Runs database migrations
# 3. Builds and starts the API service
```

The API will be available at http://localhost:5000

### Step-by-Step Execution Order

For understanding the process, you can run each step manually:

```bash
# 1. Start the database
make start-db

# 2. Run database migrations 
make run-migrations

# 3. Build the API image
make build-api

# 4. Start the API service
# (Note: make start-api does all above steps automatically)
```

### Development Workflow

```bash
# Initial development setup
make dev-setup

# Start all services for development
make start-api

# View logs
make logs-all          # All services
make logs-api          # API only  
make logs-db           # Database only

# Check service status
make status

# Stop services
make stop-all
```

## Docker Setup Instructions (Recommended)

### Quick Start with Docker

```bash
# Build the Docker image
make docker-build

# Run in development mode
make docker-run

# Access the API at http://localhost:5000
```

### Building the Docker Image

```bash
# Build with current version tag (uses git tags)
make docker-build

# Build without cache
make docker-build-no-cache

# Build manually with specific version
docker build -t rohan-rest-app:1.0.0 .
```

### Running the Container

#### Development Mode
```bash
# Using Makefile (recommended)
make docker-run

# Manual Docker command
docker run -d \
  --name rohan-rest-app \
  -p 5000:5000 \
  -e FLASK_ENV=development \
  -e FLASK_DEBUG=1 \
  -e HOST=0.0.0.0 \
  -e PORT=5000 \
  rohan-rest-app:1.0.0
```

#### Production Mode
```bash
# Using Makefile (recommended)
make docker-run-prod

# Manual Docker command
docker run -d \
  --name rohan-rest-app-prod \
  -p 5000:5000 \
  -e FLASK_ENV=production \
  -e FLASK_DEBUG=0 \
  -e HOST=0.0.0.0 \
  -e PORT=5000 \
  rohan-rest-app:1.0.0
```

#### Custom Configuration
```bash
# Using Makefile with custom variables
make docker-run-custom PORT=8080 HOST=127.0.0.1 FLASK_ENV=development

# Manual Docker command with custom port and environment
docker run -d \
  --name rohan-rest-app-custom \
  -p 8080:8080 \
  -e PORT=8080 \
  -e HOST=127.0.0.1 \
  -e FLASK_ENV=development \
  -e FLASK_DEBUG=1 \
  rohan-rest-app:1.0.0
```

### Docker Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HOST` | `0.0.0.0` | Host to bind the application |
| `PORT` | `5000` | Port to run the application |
| `FLASK_ENV` | `production` | Flask environment (development/production) |
| `FLASK_DEBUG` | `0` | Enable/disable debug mode (0/1) |

### Docker Management

```bash
# Stop and remove containers
make docker-stop

# View container logs
make docker-logs

# Get shell access to running container
make docker-shell

# Clean up Docker resources
make docker-clean

# Check image size
make docker-size
```

### Versioning Strategy

This project uses semantic versioning (semver) with Git tags:

```bash
# Create version tags
make tag-patch   # Creates v1.0.1
make tag-minor   # Creates v1.1.0
make tag-major   # Creates v2.0.0

# Push tags to repository
git push origin v1.0.0

# Build with the tagged version
make docker-build
```

Images are tagged as:
- `rohan-rest-app:1.0.0` (specific version from git tag)
- `rohan-rest-app:latest` (latest build - discouraged for production)

### Docker Image Optimization

The Dockerfile uses multi-stage builds to minimize image size:

- **Build stage**: Contains build tools (gcc, etc.) for compiling dependencies
- **Runtime stage**: Contains only runtime dependencies and application code
- **Non-root user**: Runs as `appuser` for security
- **Health checks**: Built-in health monitoring at `/healthcheck`
- **Layer optimization**: Minimizes layers and removes unnecessary files

Check image size:
```bash
make docker-size
```

## Available Make Targets

### Core Docker Compose Targets (Recommended)
```bash
make start-api       # Start complete application (DB + migrations + API)
make start-db        # Start only the database service
make run-migrations  # Run database migrations
make build-api       # Build the API Docker image
make stop-all        # Stop all services
make restart-all     # Restart all services
make dev-setup       # Complete development setup
make status          # Show status of all services
make clean-compose   # Clean up docker-compose resources
```

### Logging and Debugging Targets
```bash
make logs-all        # Show all service logs
make logs-api        # Show API logs only
make logs-db         # Show database logs only
make shell-api       # Get shell access to API container
make shell-db        # Connect to database shell (PostgreSQL)
```

### Health Check Targets
```bash
make check-db        # Check if database is running and accessible
make check-migrations # Check if migrations have been applied
```

### Legacy Docker Targets (Single Container)
```bash
make docker-build    # Build Docker image with version tag
make docker-run      # Run container in development mode
make docker-run-prod # Run container in production mode
make docker-stop     # Stop and remove containers
make docker-clean    # Clean up Docker resources
make docker-size     # Show image size
```

### Development Targets
```bash
make setup        # Set up virtual environment and install dependencies
make install      # Install dependencies
make run          # Run the Flask application locally
make dev          # Run the application in development mode
make test         # Run unit tests
make test-cov     # Run tests with coverage
make lint         # Run code linting
make format       # Format code
make clean        # Clean up generated files
make watch        # Development server with auto-reload
```

### Release Management Targets
```bash
make version      # Show current version
make tag-patch    # Create patch release tag (v1.0.1)
make tag-minor    # Create minor release tag (v1.1.0)
make tag-major    # Create major release tag (v2.0.0)
```

### Combined Workflow Targets
```bash
make build-and-run  # Build Docker image and run container
make deploy         # Build and push to registry
make all           # Run linting, tests, and build Docker image
```

### Execution Order for Production Deployment

1. **Initial Setup:**
   ```bash
   make dev-setup        # Sets up everything for first time
   ```

2. **Start Application:**
   ```bash
   make start-api        # Starts DB, runs migrations, starts API
   ```

3. **Monitor and Debug:**
   ```bash
   make status           # Check service status
   make logs-all         # View logs
   make check-db         # Verify database health
   make check-migrations # Verify migrations applied
   ```

4. **Cleanup:**
   ```bash
   make stop-all         # Stop all services
   make clean-compose    # Clean up resources
   ```

### Environment Variables

You can customize the deployment using environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `FLASK_ENV` | `production` | Flask environment (development/production) |
| `FLASK_DEBUG` | `0` | Enable/disable debug mode (0/1) |
| `API_PORT` | `5000` | Host port for API service |
| `POSTGRES_DB` | `students_db` | PostgreSQL database name |
| `POSTGRES_USER` | `postgres` | PostgreSQL username |
| `POSTGRES_PASSWORD` | `postgres` | PostgreSQL password |

Example with custom environment:
```bash
# Start with custom port and debug mode
FLASK_ENV=development FLASK_DEBUG=1 API_PORT=8080 make start-api
```

## Local Setup Instructions (Alternative)

### 1. Clone the Repository

```bash
git clone <repository-url>
cd rohan-rest-app
```

### 2. Quick Setup with Makefile

```bash
# Set up virtual environment and install dependencies
make setup

# Activate virtual environment
source venv/bin/activate

# Run the application
make run
```

### 3. Manual Setup (Alternative)

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables (optional - defaults provided)
cp .env.example .env
# Edit .env file with your configuration

# Run the application
python app.py
```

### 4. Database Migrations (Optional)

For production use with proper migrations:

```bash
# Initialize migrations
make migrate

# Apply migrations
make upgrade
```

## Environment Variables

Create a `.env` file in the project root:

```bash
# Database Configuration
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/students_db

# Flask Configuration
FLASK_ENV=development
FLASK_DEBUG=True

# API Configuration
API_VERSION=v1
PORT=5000
HOST=127.0.0.1
```

## Usage Examples

### Create a Student

```bash
curl -X POST http://localhost:5000/api/v1/students \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe", 
    "email": "john.doe@example.com",
    "age": 20,
    "grade": "A"
  }'
```

### Get All Students

```bash
curl http://localhost:5000/api/v1/students
```

### Get Student by ID

```bash
curl http://localhost:5000/api/v1/students/1
```

### Update Student

```bash
curl -X PUT http://localhost:5000/api/v1/students/1 \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Jane",
    "age": 21
  }'
```

### Delete Student

```bash
curl -X DELETE http://localhost:5000/api/v1/students/1
```

### Health Check

```bash
curl http://localhost:5000/healthcheck
```

## Available Make Commands

```bash
make help          # Show all available commands
make setup          # Set up virtual environment and dependencies
make run            # Run the application
make dev            # Run in development mode
make test           # Run unit tests
make test-cov       # Run tests with coverage
make clean          # Clean up generated files
make migrate        # Initialize database migrations
make upgrade        # Apply database migrations
```

## Testing

Run the test suite:

```bash
# Run all tests
make test

# Run tests with coverage report
make test-cov
```

## API Response Format

### Success Response

```json
{
  "message": "Student created successfully",
  "student": {
    "id": 1,
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "age": 20,
    "grade": "A",
    "enrollment_date": "2024-01-15T10:30:00",
    "created_at": "2024-01-15T10:30:00",
    "updated_at": "2024-01-15T10:30:00"
  }
}
```

### Error Response

```json
{
  "error": "Student not found"
}
```

### Paginated Response

```json
{
  "students": [...],
  "pagination": {
    "page": 1,
    "per_page": 10,
    "total": 25,
    "pages": 3,
    "has_next": true,
    "has_prev": false
  }
}
```

## Twelve-Factor App Compliance

1. **Codebase**: Single codebase tracked in version control
2. **Dependencies**: Explicitly declared in `requirements.txt`
3. **Config**: Configuration stored in environment variables
4. **Backing Services**: Database treated as attached resource
5. **Build/Release/Run**: Separated build and run stages via Makefile
6. **Processes**: Stateless application processes
7. **Port Binding**: Self-contained with configurable port
8. **Concurrency**: Scalable process model
9. **Disposability**: Fast startup and graceful shutdown
10. **Dev/Prod Parity**: Consistent environments
11. **Logs**: Structured logging to stdout
12. **Admin Processes**: Management commands via Makefile

## Production Deployment

For production deployment:

1. Set environment variables appropriately
2. Use a production WSGI server (e.g., Gunicorn)
3. Use a production database (PostgreSQL, MySQL)
4. Configure proper logging
5. Set up monitoring and health checks

```bash
# Example production run with Gunicorn
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:8000 app:app
```

## Project Structure

```
rohan-rest-app/
├── app.py              # Main application file
├── models.py           # Database models
├── config.py           # Configuration management
├── requirements.txt    # Python dependencies
├── Makefile           # Build and run commands
├── .env               # Environment variables
├── README.md          # Project documentation
├── tests/             # Unit tests
└── migrations/        # Database migrations (generated)
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `make test`
5. Submit a pull request

## License

This project is licensed under the MIT License.