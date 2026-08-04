FROM node:20-alpine AS builder

RUN apk add --no-cache python3 make g++ git

WORKDIR /app

COPY package*.json ./

RUN npm ci --legacy-peer-deps

COPY . .
RUN npm run build

FROM node:20-alpine

RUN apk add --no-cache dumb-init

WORKDIR /app

ENV NODE_ENV=production
ENV UPTIME_KUMA_DATA_DIR=/app/data

RUN mkdir -p /app/data && chown -R node:node /app

COPY --chown=node:node --from=builder /app /app

RUN npm prune --production && npm cache clean --force

USER node

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001', (r) => {r.statusCode === 200 ? process.exit(0) : process.exit(1)})"

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server/server.js"]
