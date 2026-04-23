
ARG NODE_VERSION=24.14.1

FROM node:${NODE_VERSION}-alpine as base

# Use production node environment by default.
ENV NODE_ENV production

WORKDIR /app

FROM base as builder

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM base as final

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser
USER appuser

COPY --from=builder /node_modules /node_modules
COPY --from=builder /package.json /package.json
COPY --from=builder /package-lock.json /package-lock.json

# Copy application code
COPY --chown=appuser:appuser ./app.js .

# Switch to the non-privileged user to run the application.

# Expose the port that the application listens on.
EXPOSE 3000
CMD ["node", "app.js"]
