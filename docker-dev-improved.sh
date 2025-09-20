#!/bin/bash

# Docker Development Helper Script for Acquisitions App
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if .env.development exists
check_env_file() {
    if [ ! -f ".env.development" ]; then
        print_error ".env.development file not found!"
        print_info "Please copy .env.development template and fill in your credentials"
        exit 1
    fi
}

# Function to start with Neon Local
start_neon_local() {
    print_info "Starting development environment with Neon Local..."
    check_env_file
    
    print_warning "Note: Neon Local requires valid Neon credentials"
    print_info "Make sure your .env.development has correct:"
    print_info "  - NEON_API_KEY"
    print_info "  - NEON_PROJECT_ID" 
    print_info "  - PARENT_BRANCH_ID"
    
    docker-compose --env-file .env.development -f docker-compose.dev.yml up --build
}

# Function to start with local PostgreSQL
start_local_postgres() {
    print_info "Starting development environment with local PostgreSQL..."
    check_env_file
    
    print_info "Using local PostgreSQL container (no Neon credentials required)"
    docker-compose --env-file .env.development -f docker-compose.local.yml up --build
}

# Function to test Neon credentials
test_neon_credentials() {
    print_info "Testing Neon credentials..."
    
    if [ ! -f ".env.development" ]; then
        print_error ".env.development file not found!"
        return 1
    fi
    
    # Source the environment file
    source .env.development
    
    if [ -z "$NEON_API_KEY" ] || [ -z "$NEON_PROJECT_ID" ]; then
        print_error "Missing NEON_API_KEY or NEON_PROJECT_ID in .env.development"
        return 1
    fi
    
    print_info "Testing API connection..."
    response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $NEON_API_KEY" \
        "https://console.neon.tech/api/v2/projects/$NEON_PROJECT_ID" -o /dev/null)
    
    if [ "$response" = "200" ]; then
        print_success "Neon credentials are valid!"
        return 0
    else
        print_error "Neon credentials test failed (HTTP $response)"
        print_info "Please check your NEON_API_KEY and NEON_PROJECT_ID"
        return 1
    fi
}

# Main function
case "$1" in
    "neon")
        start_neon_local
        ;;
    "local"|"postgres")
        start_local_postgres
        ;;
    "start")
        print_info "Auto-detecting best database option..."
        if test_neon_credentials; then
            print_info "Neon credentials valid, starting with Neon Local..."
            start_neon_local
        else
            print_warning "Neon credentials invalid, falling back to local PostgreSQL..."
            start_local_postgres
        fi
        ;;
    "test-neon")
        test_neon_credentials
        ;;
    "stop")
        print_info "Stopping all development environments..."
        docker-compose -f docker-compose.dev.yml down 2>/dev/null || true
        docker-compose -f docker-compose.local.yml down 2>/dev/null || true
        print_success "Development environments stopped"
        ;;
    "clean")
        print_info "Cleaning up all development environments..."
        docker-compose -f docker-compose.dev.yml down -v --rmi all 2>/dev/null || true
        docker-compose -f docker-compose.local.yml down -v --rmi all 2>/dev/null || true
        docker system prune -f
        print_success "Development environments cleaned"
        ;;
    "logs")
        print_info "Showing logs..."
        if docker-compose -f docker-compose.dev.yml ps -q | grep -q .; then
            docker-compose -f docker-compose.dev.yml logs -f
        elif docker-compose -f docker-compose.local.yml ps -q | grep -q .; then
            docker-compose -f docker-compose.local.yml logs -f
        else
            print_error "No running containers found"
        fi
        ;;
    "shell")
        print_info "Opening shell in app container..."
        if docker ps --format "table {{.Names}}" | grep -q "acquisitions-app-dev"; then
            docker-compose -f docker-compose.dev.yml exec app sh
        elif docker ps --format "table {{.Names}}" | grep -q "acquisitions-app-local"; then
            docker-compose -f docker-compose.local.yml exec app sh
        else
            print_error "No running app container found"
        fi
        ;;
    "db-shell")
        print_info "Opening database shell..."
        if docker ps --format "table {{.Names}}" | grep -q "acquisitions-neon-local"; then
            docker-compose -f docker-compose.dev.yml exec neon-local psql -h localhost -U user -d neondb
        elif docker ps --format "table {{.Names}}" | grep -q "acquisitions-postgres-local"; then
            docker-compose -f docker-compose.local.yml exec postgres psql -U postgres -d neondb
        else
            print_error "No running database container found"
        fi
        ;;
    "migrate")
        print_info "Running database migrations..."
        if docker ps --format "table {{.Names}}" | grep -q "acquisitions-app-dev"; then
            docker-compose -f docker-compose.dev.yml exec app npm run db:migrate
        elif docker ps --format "table {{.Names}}" | grep -q "acquisitions-app-local"; then
            docker-compose -f docker-compose.local.yml exec app npm run db:migrate
        else
            print_error "No running app container found"
        fi
        ;;
    "status")
        print_info "Checking development environment status..."
        echo "=== Neon Local Environment ==="
        docker-compose -f docker-compose.dev.yml ps 2>/dev/null || echo "Not running"
        echo ""
        echo "=== Local PostgreSQL Environment ==="
        docker-compose -f docker-compose.local.yml ps 2>/dev/null || echo "Not running"
        ;;
    *)
        echo "Usage: $0 {start|neon|local|postgres|test-neon|stop|clean|logs|shell|db-shell|migrate|status}"
        echo ""
        echo "Database Options:"
        echo "  start           - Auto-detect and start best database option"
        echo "  neon            - Start with Neon Local (requires valid Neon credentials)"
        echo "  local|postgres  - Start with local PostgreSQL (no Neon credentials needed)"
        echo "  test-neon       - Test Neon API credentials"
        echo ""
        echo "Management Commands:"
        echo "  stop            - Stop all development environments"
        echo "  clean           - Stop and remove all containers, volumes, and images"
        echo "  logs            - Show and follow logs"
        echo "  shell           - Open shell in app container"
        echo "  db-shell        - Open database shell"
        echo "  migrate         - Run database migrations"
        echo "  status          - Show container status"
        echo ""
        echo "Quick Start:"
        echo "  ./docker-dev-improved.sh local    # Use local PostgreSQL (recommended for first time)"
        echo "  ./docker-dev-improved.sh neon     # Use Neon Local (requires setup)"
        echo "  ./docker-dev-improved.sh start    # Auto-detect best option"
        exit 1
        ;;
esac