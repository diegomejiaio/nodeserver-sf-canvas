# Salesforce Canvas Node.js Demo

A Node.js application that demonstrates Salesforce Canvas integration, allowing you to embed external applications within Salesforce. This application handles Salesforce Canvas signed requests and displays user information securely.

## Features

- Salesforce Canvas integration
- Secure request handling with HMAC SHA-256
- EJS templating for dynamic content
- Docker support for containerization
- Azure deployment ready

## Prerequisites

- Node.js 14 or higher
- Docker
- Azure CLI (for deployment)
- Salesforce Developer Account
- Azure subscription (for cloud deployment)

## Local Development Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd nodeserver-sf-canvas
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Set environment variables:
   ```bash
   export CANVAS_CONSUMER_SECRET=your_salesforce_canvas_consumer_secret
   ```

4. Start the server:
   ```bash
   npm start
   ```

The server will start on port 3000 by default (port 80 in production).

## Docker Setup

1. Build the Docker image:
   ```bash
   docker build -t sf-canvas-webapp .
   ```

2. Run the container:
   ```bash
   docker run -p 80:80 -e CANVAS_CONSUMER_SECRET=your_secret sf-canvas-webapp
   ```

## Azure Deployment

This application includes a deployment script (`deploy.sh`) that automates the Azure deployment process:

1. Ensure you have Azure CLI installed and are logged in:
   ```bash
   az login
   ```

2. Make the deployment script executable:
   ```bash
   chmod +x deploy.sh
   ```

3. Run the deployment:
   ```bash
   ./deploy.sh
   ```

The script will:
- Create/use Azure Container Registry (ACR)
- Build and push the Docker image
- Create an App Service Plan
- Deploy to Azure App Service
- Configure environment variables

## Salesforce Canvas Configuration

1. In Salesforce Setup, navigate to `Build > Create > Connected Apps`
2. Create a new Connected App
3. Enable Canvas App Settings
4. Set the Canvas App URL to your deployed application URL
5. Generate and save the Consumer Secret
6. Configure the locations where the Canvas app will appear

## Project Structure

```
.
├── app.js              # Main application file
├── deploy.sh           # Azure deployment script
├── Dockerfile          # Docker configuration
├── package.json        # Node.js dependencies
└── views/             # EJS template files
    ├── hello.ejs      # Initial page template
    ├── index.ejs      # Main canvas view template
    ├── jsonTree.css   # Styling for JSON display
    └── jsonTree.js    # JSON viewer functionality
```

## Environment Variables

- `CANVAS_CONSUMER_SECRET`: Your Salesforce Canvas consumer secret
- `PORT`: Server port (defaults to 80 in production, 3000 in development)

## Security

The application validates Salesforce Canvas signed requests using HMAC SHA-256 signatures to ensure request authenticity.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

