#!/bin/bash

# Production Deployment Script for Acquisitions Application
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

# Check if .env.production exists
check_env_file() {
    if [ ! -f ".env.production" ]; then
        print_error ".env.production file not found!"
        print_info "Please create .env.production with your production environment variables:"
        print_info "  - DATABASE_URL=your_neon_production_database_url"
        print_info "  - ARCJET_KEY=your_production_arcjet_key"
        print_info "  - LOG_LEVEL=warn"
        exit 1
    fi
}

# Validate production environment variables
validate_production_env() {
    source .env.production
    
    if [ -z "$DATABASE_URL" ]; then
        print_error "DATABASE_URL is not set in .env.production"
        exit 1
    fi
    
    if [ -z "$ARCJET_KEY" ]; then
        print_error "ARCJET_KEY is not set in .env.production"
        exit 1
    fi
    
    if [[ ! "$DATABASE_URL" == *"neon.tech"* ]]; then
        print_warning "DATABASE_URL doesn't appear to be a Neon production URL"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_success "Production environment variables validated"
}

# Main function
case "$1" in
    "start"|"up")
        print_info "🚀 Starting production environment..."
        check_env_file
        validate_production_env
        
        print_info "Building and starting production containers..."
        docker-compose --env-file .env.production -f docker-compose.prod.yml up -d --build
        
        print_info "Waiting for application to be ready..."
        sleep 15
        
        # Test the application
        print_info "Testing application health..."
        if curl -f -H "User-Agent: Mozilla/5.0 (Health Check)" http://localhost:3000/ > /dev/null 2>&1; then
            print_success "✅ Application is running on http://localhost:3000"
            print_info "Production environment started successfully!"
        else
            print_error "❌ Application health check failed"
            print_info "Check logs with: docker-compose -f docker-compose.prod.yml logs"
            exit 1
        fi
        ;;
        
    "nginx"|"with-nginx")
        print_info "🚀 Starting production environment with Nginx reverse proxy..."
        check_env_file
        validate_production_env
        
        print_info "Building and starting production containers with Nginx..."
        docker-compose --env-file .env.production -f docker-compose.prod.yml --profile with-nginx up -d --build
        
        print_info "Waiting for services to be ready..."
        sleep 20
        
        # Test through nginx
        print_info "Testing Nginx reverse proxy..."
        if curl -f -H "User-Agent: Mozilla/5.0 (Health Check)" http://localhost/ > /dev/null 2>&1; then
            print_success "✅ Application is running behind Nginx on http://localhost"
            print_info "Direct app access: http://localhost:3000"
            print_info "Production environment with Nginx started successfully!"
        else
            print_error "❌ Nginx health check failed"
            print_info "Check logs with: docker-compose -f docker-compose.prod.yml --profile with-nginx logs"
            exit 1
        fi
        ;;
        
    "stop"|"down")
        print_info "Stopping production environment..."
        docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
        docker-compose -f docker-compose.prod.yml --profile with-nginx down 2>/dev/null || true
        print_success "Production environment stopped"
        ;;
        
    "logs")
        print_info "Showing production logs..."
        if docker-compose -f docker-compose.prod.yml ps -q | grep -q .; then
            docker-compose -f docker-compose.prod.yml logs -f
        elif docker-compose -f docker-compose.prod.yml --profile with-nginx ps -q | grep -q .; then
            docker-compose -f docker-compose.prod.yml --profile with-nginx logs -f
        else
            print_error "No running production containers found"
        fi
        ;;
        
    "status")
        print_info "Checking production environment status..."
        echo "=== App Only ==="
        docker-compose -f docker-compose.prod.yml ps 2>/dev/null || echo "Not running"
        echo ""
        echo "=== With Nginx ==="
        docker-compose -f docker-compose.prod.yml --profile with-nginx ps 2>/dev/null || echo "Not running"
        ;;
        
    "clean")
        print_info "Cleaning up production environment..."
        docker-compose -f docker-compose.prod.yml down -v --rmi all 2>/dev/null || true
        docker-compose -f docker-compose.prod.yml --profile with-nginx down -v --rmi all 2>/dev/null || true
        print_success "Production environment cleaned"
        ;;
        
    "test")
        print_info "Testing production deployment locally..."
        check_env_file
        validate_production_env
        
        print_info "This will test your production configuration locally"
        print_warning "Make sure your DATABASE_URL points to a development/staging database, not production!"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        
        # Start in test mode
        docker-compose --env-file .env.production -f docker-compose.prod.yml up --build
        ;;
        
    *)
        echo "Usage: $0 {start|nginx|stop|logs|status|clean|test}"
        echo ""
        echo "Commands:"
        echo "  start|up        - Start production environment (app only)"
        echo "  nginx           - Start with Nginx reverse proxy"
        echo "  stop|down       - Stop production environment"
        echo "  logs            - Show and follow production logs"
        echo "  status          - Show container status"
        echo "  clean           - Stop and remove all containers, volumes, and images"
        echo "  test            - Test production build locally (interactive)"
        echo ""
        echo "Examples:"
        echo "  ./deploy-prod.sh start     # Start app on port 3000"
        echo "  ./deploy-prod.sh nginx     # Start with Nginx on port 80"
        echo "  ./deploy-prod.sh logs      # View logs"
        exit 1
        ;;
esac