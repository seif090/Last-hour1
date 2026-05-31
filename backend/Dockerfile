# ================================================================
# LAST HOUR — NestJS Backend Dockerfile
# ================================================================

# ─── Build Stage ────────────────────────────────────────────────
FROM node:20-alpine AS build

WORKDIR /app

RUN apk add --no-cache python3 make g++ openssl

COPY package.json package-lock.json ./
RUN npm ci --only=production && \
    npm cache clean --force

COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src/ ./src/

RUN npm run build && \
    npm prune --production

# ─── Development Stage ──────────────────────────────────────────
FROM node:20-alpine AS development

WORKDIR /app

RUN apk add --no-cache openssl

COPY package.json package-lock.json ./
RUN npm ci && \
    npm cache clean --force

COPY . .

EXPOSE 3000 9229

CMD ["npm", "run", "start:dev"]

# ─── Production Stage ───────────────────────────────────────────
FROM node:20-alpine AS production

WORKDIR /app

RUN apk add --no-cache openssl tini && \
    addgroup -S lasthour && adduser -S lasthour -G lasthour

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package.json ./
COPY prisma/ ./prisma/

RUN npx prisma generate

USER lasthour

EXPOSE 3000

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "dist/main.js"]
