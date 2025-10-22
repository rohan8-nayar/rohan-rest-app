# Student CRUD REST API Makefile

# Variables
PYTHON = python3
PIP = pip3
FLASK = flask
VENV = venv

# Conditional activation for CI vs local development
ACTIVATE = . $(VENV)/bin/activate


# Application configuration
APP_NAME := rohan-rest-app
REGISTRY := your-registry.com  # Change this to your registry
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "1.0.0")
DEFAULT_VERSION := 1.0.0

# Docker configuration
DOCKER_IMAGE := $(REGISTRY)/$(APP_NAME)
DOCKER_TAG := $(if $(VERSION),$(VERSION),$(DEFAULT_VERSION))

# Build variables
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT := $(shell git rev-parse HEAD 2>/dev/null || echo "unknown")

# Default target
.PHONY: help
help:
	@echo "Student CRUD REST API"
	@echo "Available commands:"
	@echo ""
	@echo "Development:"
	@echo "  make setup        - Set up virtual environment and install dependencies"
	@echo "  make install      - Install dependencies"
	@echo "  make run          - Run the Flask application"
	@echo "  make dev          - Run the application in development mode"
	@echo "  make migrate      - Initialize database migrations"
	@echo "  make upgrade      - Apply database migrations"
	@echo "  make test         - Run unit tests"
	@echo "  make test-cov     - Run tests with coverage"
	@echo "  make clean        - Clean up generated files"
	@echo "  make lint         - Run code linting"
	@echo "  make format       - Format code"
	@echo ""
	@echo "Docker Operations:"
	@echo "  make docker-build    - Build Docker image with version tag"
	@echo "  make docker-run      - Run container in development mode"
	@echo "  make docker-run-prod - Run container in production mode"
	@echo "  make docker-stop     - Stop and remove container"
	@echo "  make docker-logs     - Show container logs"
	@echo "  make docker-shell    - Get shell access to container"
	@echo "  make docker-clean    - Clean up Docker resources"
	@echo "  make docker-size     - Show image size"
	@echo ""
	@echo "Release Management:"
	@echo "  make version         - Show current version"
	@echo "  make tag-patch       - Create patch release tag"
	@echo "  make tag-minor       - Create minor release tag"
	@echo "  make tag-major       - Create major release tag"
	@echo ""
	@echo "Combined Workflows:"
	@echo "  make build-and-run   - Build and run container"
	@echo "  make deploy          - Build and push to registry"
	@echo "  make all            - Run all checks and build"
	@echo ""
	@echo "CI/CD:"
	@echo "  make ci-deps         - Install system dependencies for CI"
	@echo "  make ci-install      - Install Python dependencies for CI"
	@echo "  make ci-setup-db     - Setup database for CI"
	@echo ""
	@echo "Docker Compose Operations:"
	@echo "  make compose-build   - Build all services with docker-compose"
	@echo "  make start-db        - Start only the database service"
	@echo "  make run-migrations  - Run database migrations"
	@echo "  make build-api       - Build the API Docker image"
	@echo "  make start-api       - Start complete application (DB + migrations + API)"
	@echo "  make start-all       - Alias for start-api"
	@echo "  make stop-api        - Stop the API service"
	@echo "  make stop-all        - Stop all services"
	@echo "  make restart-api     - Restart API service"
	@echo "  make restart-all     - Restart all services"
	@echo "  make logs-db         - Show database logs"
	@echo "  make logs-api        - Show API logs"
	@echo "  make logs-all        - Show all service logs"
	@echo "  make shell-db        - Connect to database shell"
	@echo "  make shell-api       - Connect to API container shell"
	@echo "  make status          - Show status of all services"
	@echo "  make clean-compose   - Clean up docker-compose resources"
	@echo "  make dev-setup       - Complete development setup"
	@echo "  make check-db        - Check if database is running"
	@echo "  make check-migrations - Check if migrations are applied"

# Set up virtual environment and install dependencies
.PHONY: setup
setup:
	@echo "Setting up virtual environment..."
	$(PYTHON) -m venv $(VENV)
	@echo "Upgrading pip..."
	$(ACTIVATE) && $(PIP) install --upgrade pip
	@echo "Installing dependencies..."
	$(ACTIVATE) && $(PIP) install -r requirements-dev.txt
	@echo "Setup complete! Activate with: source $(VENV)/bin/activate"

# Install dependencies
.PHONY: install
install:
	$(ACTIVATE) && $(PIP) install -r requirements-dev.txt

# Run the Flask application
.PHONY: run
run:
	$(ACTIVATE) && $(PYTHON) app.py

# Run in development mode
.PHONY: dev
dev:
	$(ACTIVATE) && FLASK_ENV=development $(PYTHON) app.py

# Initialize database migrations
.PHONY: migrate
migrate:
	$(ACTIVATE) && $(FLASK) db init
	$(ACTIVATE) && $(FLASK) db migrate -m "Initial migration"

# Apply database migrations
.PHONY: upgrade
upgrade:
	$(ACTIVATE) && $(FLASK) db upgrade

# Run unit tests
.PHONY: test
test:
	$(ACTIVATE) && $(PYTHON) -m pytest tests/ -v

# Run tests with coverage
.PHONY: test-cov
test-cov:
	$(ACTIVATE) && $(PYTHON) -m pytest tests/ --cov=. --cov-report=html --cov-report=term

# Clean up generated files
.PHONY: clean
clean:
	rm -rf __pycache__/
	rm -rf .pytest_cache/
	rm -rf htmlcov/
	rm -rf .coverage
	rm -rf *.pyc
	rm -rf migrations/
	find . -type d -name __pycache__ -delete
	find . -type f -name "*.pyc" -delete

# Lint code
.PHONY: lint
lint:
	$(ACTIVATE) && flake8 *.py tests/

# Format code
.PHONY: format
format:
	$(ACTIVATE) && black *.py tests/

# Build for production
.PHONY: build
build: clean install test

# Development server with auto-reload
.PHONY: watch
watch:
	$(ACTIVATE) && FLASK_ENV=development FLASK_DEBUG=1 $(PYTHON) app.py

# Docker targets
.PHONY: docker-build
docker-build: ## Build Docker image with version tag
	docker build \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg GIT_COMMIT=$(GIT_COMMIT) \
		-t $(APP_NAME):$(DOCKER_TAG) \
		-t $(APP_NAME):latest \
		.
	@echo "Built image: $(APP_NAME):$(DOCKER_TAG)"

.PHONY: docker-build-no-cache
docker-build-no-cache: ## Build Docker image without cache
	docker build --no-cache \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg GIT_COMMIT=$(GIT_COMMIT) \
		-t $(APP_NAME):$(DOCKER_TAG) \
		.

.PHONY: docker-tag
docker-tag: ## Tag image for registry
	docker tag $(APP_NAME):$(DOCKER_TAG) $(DOCKER_IMAGE):$(DOCKER_TAG)
	docker tag $(APP_NAME):$(DOCKER_TAG) $(DOCKER_IMAGE):latest

.PHONY: docker-push
docker-push: docker-tag ## Push image to registry
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)
	@echo "Pushed: $(DOCKER_IMAGE):$(DOCKER_TAG)"

.PHONY: docker-run
docker-run: ## Run Docker container in development mode
	docker run -d \
		--name $(APP_NAME) \
		-p 5000:5000 \
		-e FLASK_ENV=development \
		-e FLASK_DEBUG=1 \
		-e HOST=0.0.0.0 \
		-e PORT=5000 \
		$(APP_NAME):$(DOCKER_TAG)
	@echo "Container started: $(APP_NAME)"
	@echo "Access at: http://localhost:5000"

.PHONY: docker-run-prod
docker-run-prod: ## Run Docker container in production mode
	docker run -d \
		--name $(APP_NAME)-prod \
		-p 5000:5000 \
		-e FLASK_ENV=production \
		-e FLASK_DEBUG=0 \
		-e HOST=0.0.0.0 \
		-e PORT=5000 \
		$(APP_NAME):$(DOCKER_TAG)
	@echo "Container started: $(APP_NAME)-prod"
	@echo "Access at: http://localhost:5000"

.PHONY: docker-run-custom
docker-run-custom: ## Run with custom environment variables
	@echo "Usage: make docker-run-custom PORT=8080 HOST=127.0.0.1"
	docker run -d \
		--name $(APP_NAME)-custom \
		-p $(or $(PORT),5000):$(or $(PORT),5000) \
		-e PORT=$(or $(PORT),5000) \
		-e HOST=$(or $(HOST),0.0.0.0) \
		-e FLASK_ENV=$(or $(FLASK_ENV),production) \
		-e FLASK_DEBUG=$(or $(FLASK_DEBUG),0) \
		$(APP_NAME):$(DOCKER_TAG)

.PHONY: docker-stop
docker-stop: ## Stop running container
	-docker stop $(APP_NAME) $(APP_NAME)-prod $(APP_NAME)-custom 2>/dev/null || true
	-docker rm $(APP_NAME) $(APP_NAME)-prod $(APP_NAME)-custom 2>/dev/null || true

.PHONY: docker-logs
docker-logs: ## Show container logs
	docker logs -f $(APP_NAME)

.PHONY: docker-shell
docker-shell: ## Get shell access to running container
	docker exec -it $(APP_NAME) /bin/bash

.PHONY: docker-clean
docker-clean: docker-stop ## Clean up Docker resources
	-docker rmi $(APP_NAME):$(DOCKER_TAG) 2>/dev/null || true
	-docker rmi $(APP_NAME):latest 2>/dev/null || true
	docker system prune -f

.PHONY: docker-size
docker-size: ## Show image size
	docker images $(APP_NAME):$(DOCKER_TAG) --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Release targets
.PHONY: version
version: ## Show current version
	@echo "Current version: $(DOCKER_TAG)"

.PHONY: tag-patch
tag-patch: ## Create patch release tag
	@echo "Creating patch release..."
	$(eval CURRENT_VERSION := $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/v//'))
	$(eval NEW_VERSION := $(shell echo $(CURRENT_VERSION) | awk -F. '{print $$1"."$$2"."$$3+1}'))
	git tag v$(NEW_VERSION)
	@echo "Created tag: v$(NEW_VERSION)"
	@echo "Push with: git push origin v$(NEW_VERSION)"

.PHONY: tag-minor
tag-minor: ## Create minor release tag
	@echo "Creating minor release..."
	$(eval CURRENT_VERSION := $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/v//'))
	$(eval NEW_VERSION := $(shell echo $(CURRENT_VERSION) | awk -F. '{print $$1"."$$2+1".0"}'))
	git tag v$(NEW_VERSION)
	@echo "Created tag: v$(NEW_VERSION)"
	@echo "Push with: git push origin v$(NEW_VERSION)"

.PHONY: tag-major
tag-major: ## Create major release tag
	@echo "Creating major release..."
	$(eval CURRENT_VERSION := $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/v//'))
	$(eval NEW_VERSION := $(shell echo $(CURRENT_VERSION) | awk -F. '{print $$1+1".0.0"}'))
	git tag v$(NEW_VERSION)
	@echo "Created tag: v$(NEW_VERSION)"
	@echo "Push with: git push origin v$(NEW_VERSION)"

# Combined workflows
.PHONY: build-and-run
build-and-run: docker-build docker-run ## Build and run container

.PHONY: deploy
deploy: docker-build docker-push ## Build and push to registry

.PHONY: all
all: lint test docker-build ## Run all checks and build

# CI/CD targets
.PHONY: ci-deps
ci-deps: ## Install system dependencies for CI environment
	sudo apt-get update
	sudo apt-get install -y postgresql-client libpq-dev gcc python3-dev

.PHONY: ci-install
ci-install: ## Install CI dependencies (uses requirements.txt instead of requirements-dev.txt)
	$(PYTHON) -m pip install --upgrade pip
	$(PYTHON) -m pip install -r requirements.txt

.PHONY: ci-setup-db
ci-setup-db: ## Setup database for CI environment
	$(PYTHON) migrate.py

# Docker Compose targets
.PHONY: compose-build
compose-build: ## Build all services with docker-compose
	docker-compose build

.PHONY: start-db
start-db: ## Start only the database service
	@echo "Starting PostgreSQL database..."
	docker-compose up -d postgres
	@echo "Waiting for database to be ready..."
	@until docker-compose exec postgres pg_isready -U postgres -d students_db >/dev/null 2>&1; do \
		echo "Database is not ready yet, waiting..."; \
		sleep 2; \
	done
	@echo "Database is ready!"

.PHONY: stop-db
stop-db: ## Stop the database service
	docker-compose stop postgres

.PHONY: run-migrations
run-migrations: ## Run database migrations
	@echo "Running database migrations..."
	@if ! docker-compose ps postgres | grep -q "Up"; then \
		echo "Database is not running. Starting database first..."; \
		$(MAKE) start-db; \
	fi
	docker-compose run --rm --entrypoint="python" api migrate.py
	@echo "Migrations completed!"

.PHONY: build-api
build-api: ## Build the API Docker image
	docker-compose build api

.PHONY: start-api
start-api: start-db run-migrations build-api ## Start the complete application (DB + migrations + API)
	@echo "Starting API service..."
	docker-compose up -d api
	@echo "Application started! API available at http://localhost:5000"

.PHONY: start-all
start-all: start-api ## Alias for start-api (starts everything)

.PHONY: stop-api
stop-api: ## Stop the API service
	docker-compose stop api

.PHONY: stop-all
stop-all: ## Stop all services
	docker-compose down

.PHONY: restart-api
restart-api: ## Restart the API service
	docker-compose restart api

.PHONY: restart-all
restart-all: stop-all start-all ## Restart all services

.PHONY: logs-db
logs-db: ## Show database logs
	docker-compose logs -f postgres

.PHONY: logs-api
logs-api: ## Show API logs
	docker-compose logs -f api

.PHONY: logs-all
logs-all: ## Show all service logs
	docker-compose logs -f

.PHONY: shell-db
shell-db: ## Connect to database shell
	docker-compose exec postgres psql -U postgres -d students_db

.PHONY: shell-api
shell-api: ## Connect to API container shell
	docker-compose exec api /bin/bash

.PHONY: status
status: ## Show status of all services
	docker-compose ps

.PHONY: clean-compose
clean-compose: ## Clean up docker-compose resources
	docker-compose down -v --remove-orphans
	docker-compose rm -f
	docker volume prune -f

.PHONY: compose-push
compose-push: ## Push all services to Docker Hub
	@echo "Pushing API image to Docker Hub..."
	docker-compose push api

.PHONY: dev-setup
dev-setup: ## Complete development setup
	@echo "Setting up development environment..."
	$(MAKE) compose-build
	$(MAKE) start-db
	$(MAKE) run-migrations
	@echo "Development environment ready!"
	@echo "Run 'make start-api' to start the API service"

.PHONY: check-db
check-db: ## Check if database is running and accessible
	@if docker-compose ps postgres | grep -q "Up"; then \
		echo "✓ Database container is running"; \
		if docker-compose exec postgres pg_isready -U postgres -d students_dev >/dev/null 2>&1; then \
			echo "✓ Database is accepting connections"; \
		else \
			echo "✗ Database is not ready yet"; \
			exit 1; \
		fi \
	else \
		echo "✗ Database container is not running"; \
		exit 1; \
	fi

.PHONY: check-migrations
check-migrations: ## Check if migrations have been applied
	@echo "Checking migration status..."
	@if docker-compose exec postgres psql -U postgres -d students_db -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'student';" | grep -q "1"; then \
		echo "✓ Database migrations have been applied"; \
	else \
		echo "✗ Database migrations have not been applied"; \
		echo "Run 'make run-migrations' to apply migrations"; \
		exit 1; \
	fi