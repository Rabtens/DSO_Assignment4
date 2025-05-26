pipeline {
    agent any
    
    environment {
        // Reference stored credentials (SECURITY BEST PRACTICE #2)
        DOCKER_CREDS = credentials('dockerhub-credentials')
        IMAGE_NAME = 'my-secure-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('Prepare Secrets') {
            steps {
                script {
                    // Create .npmrc file for Docker secrets
                    writeFile file: '.npmrc', text: '''
registry=https://registry.npmjs.org/
//registry.npmjs.org/:_authToken=${NPM_TOKEN}
'''
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo 'Building Docker image with secrets...'
                    // Build with Docker secrets (SECURITY BEST PRACTICE #2)
                    sh """
                        docker buildx build \
                          --secret id=npmrc,src=./.npmrc \
                          -t ${IMAGE_NAME}:${IMAGE_TAG} \
                          --load .
                    """
                    sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest"
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo 'Deploying to Docker Hub...'
                    // Login using stored credentials (SECURITY BEST PRACTICE #2)
                    sh 'echo $DOCKER_CREDS_PSW | docker login -u $DOCKER_CREDS_USR --password-stdin'
                    
                    // Push image
                    sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} $DOCKER_CREDS_USR/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} $DOCKER_CREDS_USR/${IMAGE_NAME}:latest"
                    sh "docker push $DOCKER_CREDS_USR/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push $DOCKER_CREDS_USR/${IMAGE_NAME}:latest"
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo 'Cleaning up...'
                sh "docker logout"
                sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
                sh "docker rmi ${IMAGE_NAME}:latest || true"
                // Clean up secret files (SECURITY BEST PRACTICE #2)
                sh "rm -f .npmrc"
            }
        }
    }
}