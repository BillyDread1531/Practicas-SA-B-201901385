# =========================
# ETAPA 1: dependencias
# =========================
FROM node:22-alpine AS deps

WORKDIR /app

COPY package*.json ./

RUN npm ci --omit=dev


# =========================
# ETAPA 2: runtime
# =========================
FROM node:22-alpine AS runtime

WORKDIR /app

ENV NODE_ENV=production

# npm/npx no son necesarios para ejecutar la aplicación.
# Se eliminan del runtime para evitar arrastrar vulnerabilidades
# de las herramientas de desarrollo incluidas en la imagen base.
RUN rm -rf /usr/local/lib/node_modules/npm \
    && rm -f /usr/local/bin/npm /usr/local/bin/npx

COPY --from=deps /app/node_modules ./node_modules
COPY package*.json ./
COPY src ./src

RUN chown -R node:node /app

USER node

EXPOSE 3001

CMD ["node", "src/index.js"]
