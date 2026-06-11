# Stage 1: Install deps + generate Prisma client + compile TypeScript
FROM node:20-alpine AS builder
WORKDIR /app

# OpenSSL required by Prisma engine (Alpine 3.18+ uses OpenSSL 3.x)
RUN apk add --no-cache openssl

COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci
RUN npx prisma generate

COPY src ./src
COPY tsconfig.json ./
RUN npm run build

# Stage 2: Production image (no dev dependencies)
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# Same OpenSSL needed at runtime
RUN apk add --no-cache openssl

COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci --omit=dev

# Copy generated Prisma client (linux-musl-openssl-3.0.x binary)
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
# Copy compiled JS
COPY --from=builder /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/server.js"]
