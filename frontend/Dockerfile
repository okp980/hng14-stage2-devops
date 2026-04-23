
ARG NODE_VERSION=24.14.1

FROM node:${NODE_VERSION}-alpine as builder

# Use production node environment by default.
ENV NODE_ENV production

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM node:${NODE_VERSION}-alpine as final

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


WORKDIR /app

COPY --from=builder /app/node_modules /app/node_modules
COPY --from=builder /app/package.json /app/package.json
COPY --from=builder /app/package-lock.json /app/package-lock.json
    
# Copy application code
COPY ./app.js .

# Set the ownership of the application code to the non-privileged user.
RUN chown -R appuser:appuser /app   

# Switch to the non-privileged user to run the application.
USER appuser

# Expose the port that the application listens on.
EXPOSE 3000

# Run the application.
CMD ["node", "app.js"]
