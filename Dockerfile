# syntax=docker/dockerfile:1
FROM node:18-alpine

# Create a non-root user (SECURITY BEST PRACTICE #1)
RUN adduser -D appuser

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies using secrets (SECURITY BEST PRACTICE #2)
# This ensures sensitive info like registry tokens aren't in build history
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm install

# Copy application code
COPY . .

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user (SECURITY BEST PRACTICE #1)
USER appuser

# Expose port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]