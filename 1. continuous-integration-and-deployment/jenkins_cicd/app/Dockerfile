# FROM node:16
# WORKDIR /usr/src/app
# COPY package*.json ./
# RUN npm install
# COPY . .
# CMD ["npm", "start"]
# ---- Stage 1: Build ----
FROM node:16-alpine AS builder

# Set working directory
WORKDIR /app

# Install build dependencies 
RUN apk add --no-cache python3 make g++

# Copy package files and install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application source
COPY . .

# ---- Stage 2: Runtime ----
FROM gcr.io/distroless/nodejs16

# Set working directory
WORKDIR /app

# Copy only built app and dependencies from builder
COPY --from=builder /app .

# Run as non-root 
USER 1000

# Expose app port
EXPOSE 3000

# Start the application
CMD ["src/app.js"]
