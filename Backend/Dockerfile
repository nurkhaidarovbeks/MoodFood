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

# Stage 2: Production image
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

RUN apk add --no-cache openssl

COPY package*.json ./
COPY prisma ./prisma/

# Install all deps (need prisma CLI to generate), then prune dev deps
RUN npm ci
RUN npx prisma generate
RUN npm prune --production

# Copy compiled JS
COPY --from=builder /app/dist ./dist

EXPOSE 3000

CMD ["node", "dist/server.js"]
