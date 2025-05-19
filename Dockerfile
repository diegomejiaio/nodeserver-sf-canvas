ARG TARGETPLATFORM=linux/amd64

FROM --platform=${TARGETPLATFORM} node:20-alpine
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy application code
COPY . .

# Azure App Service expects port 80
ENV PORT=80

# Expose the port
EXPOSE 80

# Start the application
CMD ["npm", "start"]
