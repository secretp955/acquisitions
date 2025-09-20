#!/bin/bash

# Quick Start Script for Acquisitions Development Environment
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Acquisitions Development Environment${NC}"
echo ""

# Create logs directory if it doesn't exist
mkdir -p logs

# Start the development environment with local PostgreSQL
echo -e "${BLUE}📦 Starting containers...${NC}"
docker-compose --env-file .env.development -f docker-compose.local.yml up -d --build

# Wait a moment for containers to be ready
echo -e "${BLUE}⏳ Waiting for services to be ready...${NC}"
sleep 10

# Check if everything is running
if docker ps | grep -q "acquisitions-app-local"; then
    echo -e "${GREEN}✅ Application is running on http://localhost:3000${NC}"
    echo -e "${GREEN}✅ PostgreSQL database is running on localhost:5432${NC}"
    echo ""
    echo -e "${BLUE}📝 Available commands:${NC}"
    echo "  • View logs: docker-compose -f docker-compose.local.yml logs -f"
    echo "  • Stop: docker-compose -f docker-compose.local.yml down"
    echo "  • Database shell: docker exec -it acquisitions-postgres-local psql -U postgres -d neondb"
    echo "  • App shell: docker exec -it acquisitions-app-local sh"
    echo ""
    echo -e "${BLUE}🌐 Test the application:${NC}"
    echo "  • Main page: curl -H 'User-Agent: Mozilla/5.0' http://localhost:3000/"
    echo "  • API: curl -H 'User-Agent: Mozilla/5.0' http://localhost:3000/api"
    echo ""
    echo -e "${GREEN}🎉 Development environment is ready!${NC}"
else
    echo -e "${RED}❌ Failed to start the application${NC}"
    echo "Check logs with: docker-compose -f docker-compose.local.yml logs"
    exit 1
fi