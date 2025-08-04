FROM node:20-bookworm-slim
# Set Python interpreter for `node-gyp` to use
ENV PYTHON=/usr/bin/python3
# Install isolate-vm dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends python3 g++ build-essential && \
    rm -rf /var/lib/apt/lists/*
# Install sqlite3 dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*
# Use the least-privileged `node` user
USER node
WORKDIR /app
# Copy Yarn configuration files
COPY --chown=node:node .yarn ./.yarn
COPY --chown=node:node .yarnrc.yml ./
COPY --chown=node:node backstage.json ./
# Environment variables
ENV NODE_ENV=production
ENV NODE_OPTIONS="--no-node-snapshot"
# Copy skeleton first for dependency installation
COPY --chown=node:node yarn.lock package.json packages/backend/dist/skeleton.tar.gz ./
RUN tar xzf skeleton.tar.gz && rm skeleton.tar.gz
# Install dependencies
RUN --mount=type=cache,target=/home/node/.cache/yarn,sharing=locked,uid=1000,gid=1000 \
    yarn workspaces focus --all --production && rm -rf "$(yarn cache clean)"
# Copy examples and configs
COPY --chown=node:node examples ./examples
COPY --chown=node:node packages/backend/dist/bundle.tar.gz app-config.yaml ./
# Extract bundle
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz
EXPOSE 7007
CMD ["node", "packages/backend", "--config", "app-config.yaml"]