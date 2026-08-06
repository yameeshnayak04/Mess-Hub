# new_backend/Dockerfile
#
# Two stages, on purpose:
#   1. "deps"    — installs node_modules. Kept separate so Docker can reuse
#                  this layer from cache when we only change our own code,
#                  not package.json. That makes rebuilds much faster.
#   2. "runtime" — the actual image that runs. We only copy in the finished
#                  node_modules and our source files, not npm's cache or any
#                  dev tools — this keeps the final image smaller.

FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

FROM node:20-alpine AS runtime
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

EXPOSE 4000
CMD ["node", "server.js"]
