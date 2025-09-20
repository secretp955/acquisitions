# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a Node.js Express API application with PostgreSQL database integration via Drizzle ORM. It supports both local development and containerized deployment with comprehensive Docker orchestration for multiple database environments.

## Development Commands

### Quick Start
```bash
# Start development environment (auto-detects best database option)
./docker-dev-improved.sh start

# Start with local PostgreSQL (recommended for first-time setup)
./docker-dev-improved.sh local

# Start with Neon Local (requires valid Neon credentials)
./docker-dev-improved.sh neon

# Quick development start (local PostgreSQL only)
./start-dev.sh
```

### Development Workflow
```bash
# Start development server with hot reload
npm run dev

# Build and run production
npm start

# Docker development management
./docker-dev-improved.sh stop      # Stop all environments
./docker-dev-improved.sh restart   # Restart current environment
./docker-dev-improved.sh clean     # Clean up everything
./docker-dev-improved.sh logs      # View logs
./docker-dev-improved.sh shell     # Access app container shell
```

### Database Operations
```bash
# Generate Drizzle migrations
npm run db:generate

# Apply migrations (in development)
./docker-dev-improved.sh migrate

# Open Drizzle Studio
npm run db:studio

# Access database shell
./docker-dev-improved.sh db-shell
```

### Code Quality
```bash
# Linting
npm run lint
npm run lint:fix

# Code formatting
npm run format
npm run format:check
```

### Production Deployment
```bash
# Deploy production environment
./deploy-prod.sh start

# Deploy with Nginx reverse proxy
./deploy-prod.sh nginx

# Production logs
./deploy-prod.sh logs
```

## Architecture Overview

### Application Structure
- **Express.js API** with modular architecture using ES modules
- **Path Mapping**: Uses Node.js `imports` field for clean import paths (`#config/*`, `#controllers/*`, etc.)
- **Security**: Integrated with Arcjet for rate limiting and bot protection
- **Logging**: Winston logger with structured JSON logging to files
- **Authentication**: JWT-based auth with bcrypt password hashing

### Database Architecture
- **ORM**: Drizzle ORM with PostgreSQL
- **Multiple Environment Support**:
  - **Local PostgreSQL**: Full-featured local development
  - **Neon Local**: Ephemeral branch-based development with Neon proxy
  - **Neon Cloud**: Serverless PostgreSQL for production
- **Migrations**: Schema versioning via Drizzle Kit

### Container Strategy
- **Multi-stage Docker builds** for optimized production images
- **Environment-specific compose files**:
  - `docker-compose.local.yml` - Local PostgreSQL development
  - `docker-compose.dev.yml` - Neon Local development  
  - `docker-compose.prod.yml` - Production deployment
- **Health checks** and monitoring built-in
- **Optional Nginx** reverse proxy for production

### Directory Structure
```
src/
├── config/          # Database, logging, Arcjet configuration
├── controllers/     # Route handlers and business logic
├── middleware/      # Express middleware (security, auth)
├── models/          # Drizzle ORM schema definitions
├── routes/          # Express route definitions
├── services/        # Business logic and data access layer
├── utils/           # Utility functions (JWT, cookies, formatting)
└── validations/     # Zod schema validations
```

### Security Implementation
- **Arcjet Integration**: Rate limiting, bot detection, and security rules
- **Helmet**: Security headers middleware
- **CORS**: Cross-origin resource sharing configuration
- **JWT**: Secure token-based authentication
- **Input Validation**: Zod schema validation for all endpoints

## Environment Configuration

### Required Environment Variables

**Development (.env.development)**:
```bash
PORT=3000
NODE_ENV=development
DATABASE_URL=postgresql://user:password@host:port/db
ARCJET_KEY=your_arcjet_key_here
LOG_LEVEL=info

# For Neon Local (optional)
NEON_API_KEY=your_neon_api_key
NEON_PROJECT_ID=your_project_id
PARENT_BRANCH_ID=your_branch_id
```

**Production (.env.production)**:
```bash
PORT=3000
NODE_ENV=production
DATABASE_URL=postgresql://username:password@neon-host/db?sslmode=require
ARCJET_KEY=your_production_arcjet_key
LOG_LEVEL=warn
```

## Key Development Patterns

### Import Path Mapping
Uses Node.js package imports for clean module resolution:
```javascript
import logger from '#config/logger.js';
import { createUser } from '#services/auth.service.js';
import { signupSchema } from '#validations/auth.validation.js';
```

### Error Handling Strategy
- **Structured logging** with Winston for debugging
- **Consistent error responses** from controllers
- **Service layer separation** for business logic errors
- **Database error handling** with appropriate HTTP status codes

### Database Development Workflow
1. **Schema Changes**: Modify models in `src/models/`
2. **Generate Migration**: `npm run db:generate`
3. **Apply Migration**: `./docker-dev-improved.sh migrate` (dev) or manual in prod
4. **Verify**: Use Drizzle Studio or direct database access

### Authentication Flow
- **JWT tokens** stored in HTTP-only cookies
- **Password hashing** with bcrypt
- **User roles** supported in schema
- **Route protection** via middleware

## Troubleshooting

### Common Issues
- **Port conflicts**: Check if port 5432 (PostgreSQL) or 3000 (app) are in use
- **Neon Local failures**: Verify credentials with `./docker-dev-improved.sh test-neon`
- **Container health checks**: Use `./docker-dev-improved.sh logs` for debugging
- **Database connection issues**: Check DATABASE_URL format and network connectivity

### Development vs Production Database
- **Development**: Uses either local PostgreSQL or Neon Local with ephemeral branches
- **Production**: Connects directly to Neon Cloud database
- **Migrations**: Auto-applied in development, manual in production

### Security Notes
- **Arcjet Configuration**: Requires valid API key for security features to work
- **Bot Protection**: Curl requests will be blocked unless using proper User-Agent headers
- **Rate Limiting**: Applied globally, be aware during testing

### Deployment Considerations
- **Environment Variables**: Ensure all required vars are set for target environment
- **Database URL**: Must point to correct database (local/Neon Local/Neon Cloud)
- **Health Checks**: Use `/health` endpoint for monitoring
- **Nginx**: Optional reverse proxy available for production load balancing