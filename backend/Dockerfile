# Multi-stage build :
# - Stage 1 (build) installe toutes les dépendances (dev incluses) et lance les tests.
#   Si les tests échouent, l'image ne sera pas construite.
# - Stage 2 (production) ne copie que les dépendances runtime dans une image alpine légère.
#   Résultat : image finale plus petite (~150 Mo vs ~900 Mo) et surface d'attaque réduite
#   car ni les outils de test ni les sources de test ne sont présents en production.

# ── Stage 1 : build & test ──────────────────────────────────────────
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm test

# ── Stage 2 : production ────────────────────────────────────────────
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY server.js ./

USER node

EXPOSE 3000

CMD ["node", "server.js"]
