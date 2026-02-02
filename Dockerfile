# -------------------stage 1:Base and dependencies ---------------------
FROM node:18-alpine AS deps
WORKDIR /app
#copying file needed
COPY package*.json ./
#installing dependencies
RUN npm ci

#------------------stage 2: build stage ---------------------
FROM node:18-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

#removing dev dependencies and building the project
RUN npm prune --production


#------------------stage 3: final stage Runtime -----------------
FROM node:18-alpine AS runner
WORKDIR /app

#security: set environment for production
ENV NODE_ENV=production
#creating a non root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
#copying only necessary files
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/package.json ./package.json
COPY --from=builder --chown=appuser:appgroup /app/src/ ./src

USER appuser
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s \ 
CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "src/index.js"]



