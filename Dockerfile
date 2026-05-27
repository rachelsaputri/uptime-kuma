# Stage 1: Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY npm-shrinkwrap.json ./

# Install dependencies
RUN npm ci && npm cache clean --force

# Copy source code
COPY . .

# Stage 2: Production stage
FROM node:20-alpine

# Install dumb-init untuk signal handling yang baik
RUN apk add --no-cache dumb-init

WORKDIR /app

# Copy dari builder stage
COPY --from=builder --chown=node:node /app /app

# Set environment variables
ENV NODE_ENV=production
ENV UPTIME_KUMA_DATA_DIR=/app/data

# Buat direktori data dan set permission
RUN mkdir -p /app/data && chown -R node:node /app

# Switch ke non-root user
USER node

# Expose port default Uptime Kuma
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001', (r) => {r.statusCode === 200 ? process.exit(0) : process.exit(1)})"

# Gunakan dumb-init sebagai entry point
ENTRYPOINT ["dumb-init", "--"]

# Jalankan aplikasi
CMD ["node", "server/server.js"]
