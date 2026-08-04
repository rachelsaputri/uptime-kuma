FROM node:20-alpine

RUN apk add --no-cache dumb-init

WORKDIR /app

ENV NODE_ENV=production
ENV UPTIME_KUMA_DATA_DIR=/app/data

RUN mkdir -p /app/data && chown -R node:node /app
COPY --chown=node:node . .

RUN npm install --legacy-peer-deps && npm cache clean --force
RUN npm run build


USER node

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001', (r) => {r.statusCode === 200 ? process.exit(0) : process.exit(1)})"

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server/server.js"]

