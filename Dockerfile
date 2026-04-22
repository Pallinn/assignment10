# syntax=docker/dockerfile:1.7

# =============================================================================
# Builder stage — installs production dependencies only, on a fresh Node base.
# =============================================================================

FROM node:20.11-slim AS builder

WORKDIR /app

# copy package files and install only production deps
COPY app/package.json app/package-lock.json ./
RUN npm ci --omit=dev

# copy rest of the app
COPY app/ .

# =============================================================================
# Runtime stage — slim final image. Nothing from builder's caches leaks in.
# =============================================================================

FROM node:20.11-slim

WORKDIR /app

# copy app from builder
COPY --from=builder /app /app

ENV NODE_ENV=production
EXPOSE 3000

# healthcheck using node (no curl/wget available)
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"

# start app
CMD ["node", "src/index.js"]