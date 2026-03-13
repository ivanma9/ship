# Use ECR Public Node.js image (Docker Hub is blocked in government environments)
FROM public.ecr.aws/docker/library/node:20-slim

# Set working directory
WORKDIR /app

# Disable SSL strict mode for government VPN environments (MUST be before any npm commands)
RUN npm config set strict-ssl false

# Install pnpm
RUN npm install -g pnpm@9.15.4 && pnpm config set strict-ssl false

# Copy package files for dependency installation
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY api/package.json ./api/
COPY shared/package.json ./shared/

# Install all dependencies (dev included for build step)
RUN pnpm install --frozen-lockfile --ignore-scripts

# Copy source files
COPY shared/ ./shared/
COPY api/ ./api/

# Build shared types then API
RUN pnpm build:shared && pnpm build:api

# Prune to production dependencies only after build
RUN pnpm prune --prod && pnpm store prune

# Expose port
EXPOSE 80

# Set production environment
ENV NODE_ENV=production
ENV VITE_APP_ENV=production
# Default to port 80 (AWS EB); Railway overrides $PORT at runtime
ENV PORT=80

# Start the application (run migrations first to ensure schema exists)
WORKDIR /app/api
CMD ["sh", "-c", "node dist/db/migrate.js && node dist/index.js"]
