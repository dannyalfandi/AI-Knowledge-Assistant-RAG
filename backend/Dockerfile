# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# deps — install the full dependency tree (incl. dev deps: typescript, prisma
# CLI, tsx, ...) needed to generate the Prisma client and compile TypeScript.
# ---------------------------------------------------------------------------
FROM node:24-alpine AS deps
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# ---------------------------------------------------------------------------
# build — generate the Prisma client and compile src/ -> dist/.
# ---------------------------------------------------------------------------
FROM node:24-alpine AS build
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY package.json package-lock.json ./
COPY tsconfig.json ./
COPY prisma ./prisma
COPY src ./src

# Not run by `npm ci`'s postinstall (that only runs `prisma skills sync`), so
# it has to happen explicitly before `tsc` — the generator writes TypeScript
# into src/generated/prisma, which the build step below compiles like any
# other source file.
RUN npx prisma generate
RUN npm run build

# ---------------------------------------------------------------------------
# runtime — production-only node_modules + compiled output. `tsc` output
# (dist/) is what actually runs the server (`node dist/server.js`); the `.ts`
# sources are also copied because the maintenance scripts in package.json
# (db:seed, reindex, diagnose:embeddings, delete:documents, test:llm — see
# CLAUDE.md's src/scripts/ note) run via `tsx` directly against them, and are
# meant to be run in this image with `docker compose exec backend npm run
# <script>`. No devDependencies (typescript, eslint, vitest, ...) though.
# ---------------------------------------------------------------------------
FROM node:24-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY --from=build /app/dist ./dist
COPY tsconfig.json ./
COPY src ./src
# .dockerignore excludes src/generated from the build context (it's stale/
# absent on the host — regenerated fresh in the `build` stage above), so pull
# the one `prisma generate` actually produced for this build from there
# instead, overlaying it on top of the rest of src/.
COPY --from=build /app/src/generated ./src/generated
COPY prisma/schema.prisma ./prisma/schema.prisma
COPY prisma/migrations ./prisma/migrations
COPY prisma/seed.ts ./prisma/seed.ts
COPY prisma7.config.ts ./

RUN mkdir -p storage/documents && chown -R node:node /app
USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://localhost:3000/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "dist/server.js"]
