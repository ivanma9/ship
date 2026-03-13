# Production Dockerfile for Ship Web frontend
# Multi-stage: build static assets, then serve with nginx
# Context must be repo root: docker build -f web/Dockerfile .
#
# Build args (optional):
#   VITE_API_URL - API base URL for production (default: empty = relative URLs)
#   VITE_APP_ENV - production | development (default: production)
#
# Example:
#   docker build -f web/Dockerfile --build-arg VITE_API_URL=https://api.example.com .
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build
# -----------------------------------------------------------------------------
FROM public.ecr.aws/docker/library/node:20-slim AS builder

WORKDIR /app

# Disable SSL strict mode for government VPN environments
RUN npm config set strict-ssl false

# Install pnpm
RUN npm install -g pnpm@9.15.4 && pnpm config set strict-ssl false

# Build args for Vite
ARG VITE_API_URL=
ARG VITE_APP_ENV=production
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_APP_ENV=$VITE_APP_ENV

# Copy package files and workspace config
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.json ./
COPY web/package.json ./web/
COPY shared/package.json ./shared/

# Create minimal api package.json - needed for workspace
RUN mkdir -p api && echo '{"name":"@ship/api","version":"0.0.0","private":true}' > api/package.json

# Install dependencies (including devDependencies for build)
RUN pnpm install --filter @ship/web --filter @ship/shared --ignore-scripts

# Copy source code
COPY shared/ ./shared/
COPY web/ ./web/

# Build shared types, then web
RUN pnpm build:shared && pnpm --filter @ship/web build

# -----------------------------------------------------------------------------
# Stage 2: Serve with nginx
# -----------------------------------------------------------------------------
FROM nginx:alpine

# Copy built assets from builder
COPY --from=builder /app/web/dist /usr/share/nginx/html

# SPA routing: serve index.html for all routes
# API/collaboration/events are typically routed by an external reverse proxy
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
