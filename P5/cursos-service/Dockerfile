# =========================
# ETAPA 1: dependencias
# =========================
FROM node:22-alpine AS deps

WORKDIR /app

COPY package*.json ./

RUN npm install -g npm@12.0.2 && npm ci --omit=dev


# =========================
# ETAPA 2: runtime
# =========================
FROM node:22-alpine AS runtime

WORKDIR /app

ENV NODE_ENV=production

COPY --from=deps /app/node_modules ./node_modules
COPY package*.json ./
COPY src ./src

RUN chown -R node:node /app

USER node

EXPOSE 3002

CMD ["node", "src/index.js"]
