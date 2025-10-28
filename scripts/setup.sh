#!/bin/bash

# =============================================================================
# Student CRUD REST API - Dependency Installation Script
# =============================================================================
# This script installs all required dependencies for the application
# Supports: macOS (Homebrew), Debian/Ubuntu (apt), and RHEL/CentOS (yum)
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Print header
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
    elif [[ -f /etc/redhat-release ]]; then
        OS="rhel"
    else
        OS="unknown"
    fi
    print_info "Detected OS: $OS"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install system dependencies
install_system_deps() {
    print_header "Installing System Dependencies"
    
    case $OS in
        macos)
            if ! command_exists brew; then
                print_warning "Homebrew not found. Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            
            print_info "Updating Homebrew..."
            brew update
            
            print_info "Installing dependencies via Homebrew..."
            brew install python@3.13 || brew upgrade python@3.13
            brew install postgresql@15 || brew upgrade postgresql@15
            brew install docker docker-compose
            brew install git
            
            # Start PostgreSQL service (optional for local development)
            print_info "PostgreSQL installed. To start: brew services start postgresql@15"
            ;;
            
        debian)
            print_info "Updating package list..."
            sudo apt-get update
            
            print_info "Installing dependencies via apt..."
            sudo apt-get install -y \
                python3 \
                python3-pip \
                python3-venv \
                python3-dev \
                postgresql-15 \
                postgresql-client-15 \
                libpq-dev \
                gcc \
                g++ \
                make \
                git \
                curl \
                wget \
                ca-certificates \
                gnupg \
                lsb-release
            
            # Install Docker
            if ! command_exists docker; then
                print_info "Installing Docker..."
                curl -fsSL https://get.docker.com -o get-docker.sh
                sudo sh get-docker.sh
                sudo usermod -aG docker $USER
                rm get-docker.sh
                print_warning "Please log out and back in for Docker group membership to take effect"
            fi
            
            # Install Docker Compose
            if ! command_exists docker-compose; then
                print_info "Installing Docker Compose..."
                sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
            fi
            ;;
            
        rhel)
            print_info "Updating package list..."
            sudo yum update -y
            
            print_info "Installing dependencies via yum..."
            sudo yum install -y \
                python3 \
                python3-pip \
                python3-devel \
                postgresql \
                postgresql-server \
                postgresql-devel \
                gcc \
                gcc-c++ \
                make \
                git \
                curl \
                wget
            
            # Install Docker
            if ! command_exists docker; then
                print_info "Installing Docker..."
                sudo yum install -y yum-utils
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                sudo yum install -y docker-ce docker-ce-cli containerd.io
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -aG docker $USER
                print_warning "Please log out and back in for Docker group membership to take effect"
            fi
            ;;
            
        *)
            print_error "Unsupported operating system"
            exit 1
            ;;
    esac
    
    print_success "System dependencies installed successfully!"
}

# Verify Python installation
verify_python() {
    print_header "Verifying Python Installation"
    
    if ! command_exists python3; then
        print_error "Python 3 is not installed"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    print_success "Python version: $PYTHON_VERSION"
    
    # Check if Python version is at least 3.8
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
    
    if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
        print_error "Python 3.8 or higher is required"
        exit 1
    fi
}

# Setup Python virtual environment
setup_venv() {
    print_header "Setting up Python Virtual Environment"
    
    if [ -d "venv" ]; then
        print_warning "Virtual environment already exists"
        read -p "Do you want to recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Removing existing virtual environment..."
            rm -rf venv
        else
            print_info "Skipping virtual environment creation"
            return
        fi
    fi
    
    print_info "Creating virtual environment..."
    python3 -m venv venv
    
    print_success "Virtual environment created successfully!"
}

# Install Python dependencies
install_python_deps() {
    print_header "Installing Python Dependencies"
    
    if [ ! -d "venv" ]; then
        print_error "Virtual environment not found. Run setup_venv first."
        exit 1
    fi
    
    print_info "Activating virtual environment..."
    source venv/bin/activate
    
    print_info "Upgrading pip..."
    pip install --upgrade pip setuptools wheel
    
    print_info "Installing production dependencies..."
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
        print_success "Production dependencies installed!"
    else
        print_warning "requirements.txt not found"
    fi
    
    print_info "Installing development dependencies..."
    if [ -f "requirements-dev.txt" ]; then
        pip install -r requirements-dev.txt
        print_success "Development dependencies installed!"
    else
        print_warning "requirements-dev.txt not found"
    fi
    
    print_info "Installed packages:"
    pip list
}

# Verify Docker installation
verify_docker() {
    print_header "Verifying Docker Installation"
    
    if ! command_exists docker; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    DOCKER_VERSION=$(docker --version)
    print_success "Docker: $DOCKER_VERSION"
    
    if ! command_exists docker-compose; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    
    COMPOSE_VERSION=$(docker-compose --version)
    print_success "Docker Compose: $COMPOSE_VERSION"
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    
    print_success "Docker is running!"
}

# Setup database (optional)
setup_database() {
    print_header "Database Setup"
    
    read -p "Do you want to set up PostgreSQL database using Docker? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping database setup"
        return
    fi
    
    print_info "Starting PostgreSQL database..."
    make start-db || docker-compose up -d postgres
    
    print_info "Waiting for database to be ready..."
    sleep 5
    
    print_info "Running migrations..."
    make run-migrations || docker-compose run --rm --entrypoint="python" api migrate.py
    
    print_success "Database setup complete!"
}

# Print summary
print_summary() {
    print_header "Installation Summary"
    
    echo ""
    echo -e "${GREEN}✓${NC} System dependencies installed"
    echo -e "${GREEN}✓${NC} Python $(python3 --version 2>&1 | awk '{print $2}') verified"
    echo -e "${GREEN}✓${NC} Virtual environment created"
    echo -e "${GREEN}✓${NC} Python dependencies installed"
    echo -e "${GREEN}✓${NC} Docker $(docker --version 2>&1 | awk '{print $3}' | tr -d ',') verified"
    echo -e "${GREEN}✓${NC} Docker Compose $(docker-compose --version 2>&1 | awk '{print $4}' | tr -d ',') verified"
    echo ""
    print_success "All dependencies installed successfully!"
    echo ""
    print_info "Next steps:"
    echo "  1. Activate virtual environment: source venv/bin/activate"
    echo "  2. Run tests: make test"
    echo "  3. Start the application: make start-api"
    echo "  4. Access API at: http://localhost:8080"
    echo "  5. View available commands: make help"
    echo ""
}

# Main installation flow
main() {
    print_header "Student CRUD REST API - Dependency Installation"
    echo ""
    
    # Change to script directory's parent (project root)
    cd "$(dirname "$0")/.."
    
    detect_os
    
    # Ask for installation mode
    echo ""
    echo "Select installation mode:"
    echo "  1) Full installation (system + Python deps)"
    echo "  2) Python dependencies only"
    echo "  3) System dependencies only"
    echo "  4) Verification only"
    read -p "Enter choice (1-4): " choice
    
    case $choice in
        1)
            install_system_deps
            verify_python
            setup_venv
            install_python_deps
            verify_docker
            setup_database
            print_summary
            ;;
        2)
            verify_python
            setup_venv
            install_python_deps
            print_success "Python dependencies installed!"
            ;;
        3)
            install_system_deps
            verify_python
            verify_docker
            print_success "System dependencies installed!"
            ;;
        4)
            verify_python
            verify_docker
            if [ -d "venv" ]; then
                source venv/bin/activate
                print_info "Python packages:"
                pip list
            fi
            print_success "Verification complete!"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
