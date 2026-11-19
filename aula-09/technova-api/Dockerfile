# ============================================
# Estágio 1: dependências de produção (builder)
# ============================================
FROM node:20-alpine AS deps
WORKDIR /app
# package*.json primeiro: a camada do npm ci só é refeita se as dependências mudarem
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# ============================================
# Estágio 2: runtime (imagem final enxuta)
# ============================================
FROM node:20-alpine AS production

LABEL org.opencontainers.image.title="technova-api" \
      org.opencontainers.image.description="TechNova API - aula 09 (Amazon ECR)" \
      org.opencontainers.image.source="https://github.com/rafadical/unifaat-devops-portfolio" \
      org.opencontainers.image.authors="rafael nogueira maruca"

WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node package.json server.js ./

# Usuário não-root (já existe na imagem oficial do Node)
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "server.js"]
