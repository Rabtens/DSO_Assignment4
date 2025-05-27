# Secure CI/CD Pipeline Assignment

# Overview
This project demonstrates how to build secure CI/CD pipelines using Docker, Jenkins, and GitHub Actions. The focus is on implementing security best practices to prevent common vulnerabilities in deployment processes.

# Table of Contents

- Docker Security Implementation
- Jenkins Secure Pipeline
- GitHub Actions Secure Pipeline
- Screenshots
- Security Benefits
- Setup Instructions
- Conclusion

### Docker Security Implementation

### 1. Non-Root User Setup
To improve container security, I created a non-root user to run the application instead of using the default root user.

### Dockerfile:
dockerfileFROM node:18-alpine

# Create a non-root user
```
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Change ownership to non-root user
RUN chown -R nextjs:nodejs /app
USER nextjs

# Expose port
EXPOSE 3000

# Start application
CMD ["npm", "start"]

```
### Why this matters:
-  Running containers as root can be dangerous because if someone breaks into the container, they have full system privileges. Using a non-root user limits what an attacker can do.

### 2. Docker Secrets Management

Instead of putting sensitive information directly in the Dockerfile, I used Docker secrets to handle sensitive data securely.

```
Example of what NOT to do:
dockerfileENV API_KEY=secret123  # This is bad - secrets visible in image layers
```
```
Secure approach:
dockerfile# Secrets are passed at runtime, not build time
# Use environment variables or Docker secrets for sensitive data
```

# Jenkins Secure Pipeline
### Pipeline Configuration
I set up a Jenkins pipeline that builds and pushes Docker images securely using stored credentials.

### Jenkinsfile:
```
pipeline {
    agent any
    
    environment {
        DOCKER_CREDS = credentials('docker-hub-creds')
        IMAGE_NAME = 'your-username/my-secure-app'
    }
    
    stages {
        stage('Build') {
            steps {
                echo 'Building Docker image...'
                sh 'docker build -t $IMAGE_NAME .'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running security checks...'
                // Add security scanning here if needed
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Pushing to Docker Hub...'
                sh '''
                    docker login -u $DOCKER_CREDS_USR -p $DOCKER_CREDS_PSW
                    docker tag $IMAGE_NAME $IMAGE_NAME:latest
                    docker push $IMAGE_NAME:latest
                '''
            }
        }
    }
    
    post {
        always {
            sh 'docker logout'
            echo 'Pipeline completed'
        }
    }
}
```
### Security Features in Jenkins Pipeline:

- Credential Management: Docker Hub credentials are stored securely in Jenkins and referenced using credentials() function

- No Hardcoded Secrets: Passwords and usernames are never visible in the pipeline code

- Automatic Logout: Always logout from Docker Hub after pushing to prevent credential reuse

# GitHub Actions Secure Pipeline
Workflow Configuration
The GitHub Actions workflow builds and deploys the Docker image using repository secrets.

### .github/workflows/docker-build.yml:

```
yamlname: Secure Docker Build and Deploy

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Login to Docker Hub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        push: ${{ github.ref == 'refs/heads/main' }}
        tags: |
          ${{ secrets.DOCKERHUB_USERNAME }}/my-secure-app:latest
          ${{ secrets.DOCKERHUB_USERNAME }}/my-secure-app:${{ github.sha }}
        platforms: linux/amd64,linux/arm64
```

### Security Features in GitHub Actions:

- Repository Secrets: Sensitive data is stored in GitHub repository secrets
- Conditional Deployment: Only pushes to Docker Hub when code is merged to main branch
- Multiple Tags: Creates both latest and commit-specific tags for better version control
- Multi-platform Support: Builds for different architectures

# Screenshots
### Jenkins Pipeline Success

![alt text](<screenshots/Screenshot from 2025-05-26 22-24-07.png>)

![alt text](<screenshots/Screenshot from 2025-05-26 22-27-23.png>)

Successful Jenkins pipeline execution with Docker image pushed to Docker Hub

### GitHub Actions Workflow Success

![alt text](<screenshots/Screenshot from 2025-05-26 22-15-20.png>)

![alt text](<screenshots/Screenshot from 2025-05-26 22-17-00.png>)

![alt text](<screenshots/Screenshot from 2025-05-26 22-21-19.png>)

Successful GitHub Actions workflow with secure Docker build and deployment

### Docker Hub Repository

![alt text](<screenshots/Screenshot from 2025-05-26 22-29-50.png>)

Docker image successfully pushed to Docker Hub repository

### Security Benefits
### What is Achieved:

- No Exposed Secrets: All sensitive information is stored securely and never appears in logs or code
- Reduced Attack Surface: Non-root containers limit potential damage from security breaches
- Controlled Deployments: Only authorized branches can deploy to production
- Audit Trail: All deployments are logged and traceable
- Credential Isolation: Different environments use separate credentials

### Common Security Issues Prevented:

- Secret Leakage: Credentials appearing in build logs or image layers
- Control takeover: Containers running with unnecessary root privileges
- Unauthorized Deployments: Deployments from feature branches or unauthorized users
- Credential Reuse: Long-lived sessions that could be hijacked

# Setup Instructions
### For Jenkins:

1. Install Docker and Jenkins on your server
2. Add Docker Hub credentials in Jenkins under "Manage Jenkins" > "Credentials"
3. Create a new pipeline job and point it to your repository
4. The Jenkinsfile will be automatically detected and executed

# For GitHub Actions:

1. Go to your GitHub repository settings
2. Navigate to "Secrets and variables" > "Actions"
3. Add DOCKERHUB_USERNAME and DOCKERHUB_TOKEN as repository secrets
4. Push the workflow file to .github/workflows/ directory
5. The workflow will trigger automatically on push to main branch

# Conclusion
This assignment demonstrates how to implement secure CI/CD pipelines that protect against common security vulnerabilities. By following these practices, we ensure that our deployment process is both automated and secure, reducing the risk of exposing sensitive information or deploying vulnerable applications.

The key takeaway is that security should be built into the CI/CD process from the beginning, not added as an afterthought. Each step in our pipeline includes security considerations that help protect our applications and infrastructure.