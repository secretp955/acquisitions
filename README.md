# Acquisitions Application

A Node.js Express application with Neon Database integration, fully dockerized for both development and production environments.

## 🏗️ Architecture Overview

### Development Environment

- **Option 1**: Neon Local proxy with ephemeral branches
- **Option 2**: Local PostgreSQL container (fallback)
- Hot reload enabled for development
- Drizzle ORM with automatic migrations

### Production Environment

- Direct connection to Neon Cloud Database
- Optimized Docker images with multi-stage builds
- Health checks and monitoring
- Optional Nginx reverse proxy

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 18+ (for local development)
- Neon Database account (optional for local PostgreSQL)

### Option 1: Local PostgreSQL (Recommended for First Time)

```bash
# Clone and setup
git clone <your-repo-url>
cd acquisitions

# Start with local PostgreSQL (no Neon credentials needed)
./docker-dev-improved.sh local
```

### Option 2: Neon Local (Advanced)

1. **Setup Neon credentials in `.env.development`:**

```bash
# Get these from https://console.neon.tech/
NEON_API_KEY=napi_your_api_key_here
NEON_PROJECT_ID=your-project-id
PARENT_BRANCH_ID=your-main-branch-id
```

2. **Test credentials and start:**

```bash
# Test your Neon credentials
./docker-dev-improved.sh test-neon

# Start with Neon Local
./docker-dev-improved.sh neon
```

### Auto-Detection

```bash
# Automatically choose best option based on credentials
./docker-dev-improved.sh start
```

## 📋 Environment Configuration

### Development (.env.development)

```bash
# Server Configuration
PORT=3000
NODE_ENV=development
LOG_LEVEL=info

# Database Configuration
# For local PostgreSQL:
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/neondb
# For Neon Local:
DATABASE_URL=postgresql://user:password@neon-local:5432/neondb

# Neon Local Configuration (only needed for Neon Local)
NEON_API_KEY=your_neon_api_key_here
NEON_PROJECT_ID=your_neon_project_id_here
PARENT_BRANCH_ID=your_main_branch_id_here

# Arcjet Configuration
ARCJET_KEY=your_arcjet_key_here

# Development settings
DEBUG=true
```

### Production (.env.production)

```bash
# Server Configuration
PORT=3000
NODE_ENV=production
LOG_LEVEL=warn

# Production Database (Neon Cloud)
DATABASE_URL=postgresql://username:password@ep-xxx-xxx.us-east-2.aws.neon.tech/neondb?sslmode=require

# Arcjet Configuration
ARCJET_KEY=your_production_arcjet_key_here

# Production settings
DEBUG=false
```

## 🐳 Docker Commands

### Development Management

```bash
# Start development environment
./docker-dev-improved.sh start           # Auto-detect best database
./docker-dev-improved.sh local           # Use local PostgreSQL
./docker-dev-improved.sh neon            # Use Neon Local

# Management
./docker-dev-improved.sh stop            # Stop all environments
./docker-dev-improved.sh restart         # Restart current environment
./docker-dev-improved.sh clean           # Clean up everything

# Debugging
./docker-dev-improved.sh logs            # View logs
./docker-dev-improved.sh status          # Check container status
./docker-dev-improved.sh shell           # Access app container shell
./docker-dev-improved.sh db-shell        # Access database shell

# Database operations
./docker-dev-improved.sh migrate         # Run migrations
```

### Production Deployment

```bash
# Simple production deployment
./deploy-prod.sh start

# With nginx reverse proxy
./deploy-prod.sh nginx

# Manual deployment
docker-compose --env-file .env.production -f docker-compose.prod.yml up -d

# Check health (note: use proper User-Agent for Arcjet)
curl -H "User-Agent: Mozilla/5.0" http://localhost:3000/
```

## 📁 Project Structure

```
acquisitions/
├── src/                          # Application source code
│   ├── config/                   # Configuration files
│   ├── controllers/              # Route controllers
│   ├── middleware/               # Express middleware
│   ├── models/                   # Drizzle ORM models
│   ├── routes/                   # API routes
│   ├── services/                 # Business logic
│   └── utils/                    # Utility functions
├── scripts/                      # Database and utility scripts
│   └── init-db.sql              # Local PostgreSQL initialization
├── Dockerfile                    # Multi-stage Docker build
├── docker-compose.dev.yml        # Development with Neon Local
├── docker-compose.local.yml      # Development with local PostgreSQL
├── docker-compose.prod.yml       # Production deployment
├── docker-dev-improved.sh        # Development helper script
├── start-dev.sh                  # Quick development start
├── deploy-prod.sh                # Production deployment script
├── nginx/                        # Nginx configuration for production
│   └── nginx.conf               # Reverse proxy configuration
├── .env.development              # Development environment variables
├── .env.production               # Production environment variables
└── drizzle.config.js            # Drizzle ORM configuration
```

## 🗄️ Database Setup

### Drizzle ORM Commands

```bash
# Generate migrations
npm run db:generate

# Apply migrations (in development)
./docker-dev-improved.sh migrate

# Open Drizzle Studio
npm run db:studio
```

### Direct Database Access

```bash
# Access database shell
./docker-dev-improved.sh db-shell

# For local PostgreSQL:
psql -U postgres -d neondb

# For Neon Local:
psql -h localhost -U user -d neondb
```

## 🌐 Database Environment Strategy

### Development Options

1. **Local PostgreSQL** (Recommended for beginners):
   - ✅ No external dependencies
   - ✅ Fast setup and reliable
   - ✅ Full PostgreSQL features
   - ❌ No branch management features

2. **Neon Local** (Advanced):
   - ✅ Ephemeral database branches
   - ✅ Matches production environment
   - ✅ Automatic cleanup on container stop
   - ❌ Requires Neon account and valid credentials
   - ❌ Additional complexity

### Production

- **Neon Cloud Database**:
  - ✅ Serverless scaling
  - ✅ Automatic backups
  - ✅ Branch-based workflows
  - ✅ Global edge network

## 🔧 Troubleshooting

### Neon Local Issues

If Neon Local fails to start:

1. **Check credentials:**

```bash
./docker-dev-improved.sh test-neon
```

2. **Verify project access:**
   - Go to https://console.neon.tech/
   - Ensure API key has correct permissions
   - Verify project ID format

3. **Fallback to local PostgreSQL:**

```bash
./docker-dev-improved.sh local
```

### Common Issues

**Port conflicts:**

```bash
# Check what's using port 5432
sudo lsof -i :5432
# Stop conflicting services
brew services stop postgresql
```

**Permission issues:**

```bash
# Ensure scripts are executable
chmod +x docker-dev-improved.sh
```

**Container health check failures:**

```bash
# Check container logs
./docker-dev-improved.sh logs
```

## 🚀 Deployment

### Local Production Testing

```bash
# Test production build locally
docker-compose -f docker-compose.prod.yml --env-file .env.production up
```

### Cloud Deployment

1. **Set up environment variables** in your cloud provider
2. **Configure DATABASE_URL** to point to your Neon production database
3. **Deploy using your preferred method:**
   - Docker Swarm
   - Kubernetes
   - Cloud provider container services

### Environment Variable Checklist

**Development:**

- [ ] PORT
- [ ] NODE_ENV=development
- [ ] DATABASE_URL (local or Neon Local)
- [ ] ARCJET_KEY
- [ ] NEON\_\* credentials (if using Neon Local)

**Production:**

- [ ] PORT
- [ ] NODE_ENV=production
- [ ] DATABASE_URL (Neon Cloud)
- [ ] ARCJET_KEY (production key)

## 📖 API Documentation

### Health Check

```bash
GET /health
# Returns: {"status": "OK", "timestamp": "...", "uptime": 123}
```

### Authentication Routes

```bash
POST /api/auth/register
POST /api/auth/login
GET  /api/auth/profile
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Set up development environment: `./docker-dev-improved.sh local`
4. Make your changes
5. Run tests and linting
6. Submit a pull request

## 📄 License

ISC License - see LICENSE file for details.

---

## 🆘 Need Help?

- **Neon Documentation**: https://neon.com/docs
- **Docker Compose Reference**: https://docs.docker.com/compose/
- **Drizzle ORM Docs**: https://orm.drizzle.team/

**Quick Commands Reference:**

```bash
# Development
./start-dev.sh                    # Quick start with local PostgreSQL
./docker-dev-improved.sh local    # Start with local PostgreSQL
./docker-dev-improved.sh neon     # Start with Neon Local
./docker-dev-improved.sh stop     # Stop everything

# Production
./deploy-prod.sh start            # Start production (app only)
./deploy-prod.sh nginx            # Start with Nginx reverse proxy
./deploy-prod.sh logs             # View production logs
./deploy-prod.sh stop             # Stop production environment
```
