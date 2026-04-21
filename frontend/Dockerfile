
ARG NODE_VERSION=24.14.1

FROM node:${NODE_VERSION}-alpine as base

# Use production node environment by default.
ENV NODE_ENV production

WORKDIR /app

FROM base as builder
# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.npm to speed up subsequent builds.
# Leverage a bind mounts to package.json and package-lock.json to avoid having to copy them into
# into this layer.
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

FROM base as final

# Run the application as a non-root user.
USER node

COPY --from=builder /app/node_modules /app/node_modules
COPY --from=builder /app/package.json /app/package.json
COPY --from=builder /app/package-lock.json /app/package-lock.json

# Copy application code
COPY --chown=appuser:appuser ./app.js .

# Switch to the non-privileged user to run the application.
USER appuser

# Expose the port that the application listens on.
EXPOSE 3000
CMD ["node", "app.js"]
