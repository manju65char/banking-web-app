pipeline {
    agent any
    
    tools {
        jdk 'jdk-21'
        maven 'maven-3.9'
    }
    
    environment {
        PROJECT_NAME = "banking-web-app"
        RELEASE_NAME = "banking-web-app"
        DOCKER_IMAGE = 'manjunathachar/banking-web-app'
        CHART_PATH = "./infra/helm/banking-web-app"
        NAMESPACE = "banking-app"
        IMAGE_SECRET = "regcred"
        DOCKERHUB_CREDENTIAL = 'dockerhub-creds'
        KUBECONFIG_CREDENTIAL = 'kubeconfig'
    }
    
    stages {
        stage('Build and Test') {
            steps {
                script {
                    echo 'Building application with Maven...'
                    sh 'mvn -B package --file pom.xml -DskipTests'
                    
                    // Archive artifacts
                    archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: false
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    echo 'Running tests...'
                    sh 'mvn test'
                }
            }
            post {
                always {
                    publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    sh """
                        docker build -t ${env.DOCKER_IMAGE}:${env.GIT_COMMIT} .
                        docker tag ${env.DOCKER_IMAGE}:${env.GIT_COMMIT} ${env.DOCKER_IMAGE}:latest
                    """
                    echo "Built Docker image: ${env.DOCKER_IMAGE}:${env.GIT_COMMIT}"
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo 'Pushing Docker image to Docker Hub...'
                    
                    withCredentials([usernamePassword(
                        credentialsId: env.DOCKERHUB_CREDENTIAL, 
                        passwordVariable: 'DOCKER_PASSWORD', 
                        usernameVariable: 'DOCKER_USERNAME'
                    )]) {
                        sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                        sh "docker push ${env.DOCKER_IMAGE}:${env.GIT_COMMIT}"
                        sh "docker push ${env.DOCKER_IMAGE}:latest"
                    }
                    
                    echo "Successfully pushed ${env.DOCKER_IMAGE}:${env.GIT_COMMIT}"
                }
            }
        }
        
        stage('Pre-deployment') {
            steps {
                script {
                    echo 'Updating Helm values...'
                    sh """
                        sed -i "s+latest+${env.GIT_COMMIT}+g" ${env.CHART_PATH}/values.yaml
                    """
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                script {
                    echo 'Deploying to EKS cluster...'
                    
                    withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIAL, variable: 'KUBECONFIG')]) {
                        // Create namespace if it doesn't exist
                        sh """
                            kubectl get namespace ${env.NAMESPACE} || kubectl create namespace ${env.NAMESPACE}
                        """
                        
                        // Create Docker registry secret if it doesn't exist
                        withCredentials([usernamePassword(
                            credentialsId: env.DOCKERHUB_CREDENTIAL, 
                            passwordVariable: 'DOCKER_PASSWORD', 
                            usernameVariable: 'DOCKER_USERNAME'
                        )]) {
                            sh """
                                kubectl delete secret ${env.IMAGE_SECRET} -n ${env.NAMESPACE} --ignore-not-found
                                kubectl create secret docker-registry ${env.IMAGE_SECRET} \
                                  --docker-server=https://index.docker.io/v1/ \
                                  --docker-username=${DOCKER_USERNAME} \
                                  --docker-password=${DOCKER_PASSWORD} \
                                  --docker-email=manjunathachar@example.com \
                                  -n ${env.NAMESPACE}
                            """
                        }
                        
                        // Deploy using Helm
                        sh """
                            helm upgrade --install ${env.RELEASE_NAME} ${env.CHART_PATH} \
                              --namespace ${env.NAMESPACE} \
                              --set image.repository=${env.DOCKER_IMAGE} \
                              --set image.tag=${env.GIT_COMMIT} \
                              --wait --timeout=10m
                        """
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIAL, variable: 'KUBECONFIG')]) {
                        echo 'Verifying deployment...'
                        
                        // Check deployment status
                        sh "kubectl get deployments -n ${env.NAMESPACE}"
                        sh "kubectl get pods -n ${env.NAMESPACE}"
                        sh "kubectl get services -n ${env.NAMESPACE}"
                        
                        // Wait for deployment to be ready
                        sh "kubectl wait --for=condition=available --timeout=300s deployment/${env.RELEASE_NAME} -n ${env.NAMESPACE}"
                        
                        // Get service endpoint
                        sh """
                            echo "=== Service Information ==="
                            kubectl get service ${env.RELEASE_NAME} -n ${env.NAMESPACE} -o wide
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Clean up Docker images to save space
                sh "docker rmi ${env.DOCKER_IMAGE}:${env.DOCKER_TAG} || true"
                sh "docker system prune -f || true"
                
                echo "Pipeline completed for build ${env.BUILD_NUMBER}"
            }
        }
        
        success {
            script {
                echo "✅ Pipeline completed successfully!"
                echo "🐳 Docker image: ${env.DOCKER_IMAGE}:${env.GIT_COMMIT}"
                echo "🚀 Deployed to namespace: ${env.NAMESPACE}"
                
                withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIAL, variable: 'KUBECONFIG')]) {
                    // Get the service URL
                    def serviceInfo = sh(
                        script: "kubectl get service ${env.RELEASE_NAME} -n ${env.NAMESPACE} -o wide",
                        returnStdout: true
                    ).trim()
                    
                    if (serviceInfo) {
                        echo "🌐 Service Details: ${serviceInfo}"
                    }
                }
            }
        }
        
        failure {
            script {
                echo "❌ Pipeline failed at build ${env.BUILD_NUMBER}"
                echo "Check logs above for error details"
            }
        }
        
        cleanup {
            script {
                // Clean up Docker images to save space
                sh "docker rmi ${env.DOCKER_IMAGE}:${env.GIT_COMMIT} || true"
                sh "docker system prune -f || true"
            }
            // Clean workspace
            cleanWs()
        }
    }
}
