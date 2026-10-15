FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
COPY tsconfig.json ./
COPY prisma ./prisma
COPY src ./src
RUN npm ci
RUN npx prisma generate
RUN npm run build

# One-shot migration runner. Reuses the build stage so the Prisma CLI and the
# schema are pinned to the image instead of being downloaded at deploy time.
FROM build AS migrate
CMD ["npx", "prisma", "migrate", "deploy"]

FROM node:20-alpine AS runtime
WORKDIR /app
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 appuser

COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/node_modules/@prisma ./node_modules/@prisma
COPY package.json ./

USER appuser
EXPOSE 3000

# Probe the API's own PORT so platforms that inject a different port still get
# a working healthcheck. The worker shares this image but never serves HTTP, so
# deployments must disable the probe for the worker (docker-compose.yml does
# this; PaaS healthcheck settings should override it too).
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||3000)+'/health/live',(r)=>{process.exit(r.statusCode===200?0:1)}).on('error',()=>process.exit(1))"

ENV NODE_ENV=production
CMD ["node", "dist/server.js"]
