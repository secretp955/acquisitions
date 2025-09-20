# Multi-stage Dockerfile for Acquisitions application
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./
RUN npm ci --only=production && npm cache clean --force

# Development image
FROM base AS development
WORKDIR /app

# Copy package files and install all dependencies (including dev dependencies)
COPY package.json package-lock.json ./
RUN npm ci

# Copy source code
COPY . .

# Create a non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs

# Create logs directory with proper permissions
RUN mkdir -p logs && chown nodejs:nodejs logs

# Change ownership of the app directory to the nodejs user
USER nodejs

# Expose port
EXPOSE 3000

# Command for development (with hot reload)
CMD ["npm", "run", "dev"]

# Production builder
FROM base AS builder
WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./
RUN npm ci

# Copy source code
COPY . .

# Production image
FROM base AS production
WORKDIR /app

# Create a non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs

# Copy production dependencies from deps stage
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy source code
COPY --chown=nodejs:nodejs . .

# Create logs directory with proper permissions
RUN mkdir -p logs && chown nodejs:nodejs logs

# Switch to the nodejs user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "const http = require('http'); \
  const options = { host: 'localhost', port: process.env.PORT || 3000, path: '/', timeout: 2000, headers: { 'User-Agent': 'Docker-Health-Check/1.0' } }; \
  const req = http.request(options, (res) => { \
    process.exit(res.statusCode === 200 ? 0 : 1); \
  }); \
  req.on('error', () => process.exit(1)); \
  req.end();"

# Command for production
CMD ["node", "src/index.js"]
