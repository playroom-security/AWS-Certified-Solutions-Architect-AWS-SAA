# SAA Study Project 2.4 - Users Service Dockerfile
# Multi-stage build: keeps the final image small by not including dev tools

# ── Stage 1: Install dependencies ────────────────────────────────────────────
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev

# ── Stage 2: Production image ─────────────────────────────────────────────────
FROM node:20-alpine AS production
WORKDIR /app

# Create a non-root user for security best practice
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only production node_modules from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY app.js ./

# Switch to non-root user
USER appuser

# Expose the application port
EXPOSE 3000

# Health check — Docker/ECS will restart the container if this fails
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/users/health || exit 1

# Start the application
CMD ["node", "app.js"]
