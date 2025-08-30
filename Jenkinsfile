pipeline {
    agent any
    
    environment {
        JAVA_HOME = '/usr/lib/jvm/java-17-openjdk-amd64'
        PATH = "$JAVA_HOME/bin:$PATH"
        PROJECT_NAME = "banking-web-app"
        RELEASE_NAME = "banking-web-app"
        DOCKER_IMAGE = 'manjunathachar/banking-web-app'
        CHART_PATH = "./infra/helm/banking-web-app"
        NAMESPACE = "banking-app"
        IMAGE_SECRET = "regcred"
        DOCKERHUB_CREDENTIAL = 'dockerhub-creds'
    }
    
    stages {
        stage('Build and Test') {
            steps {
                script {
                    echo 'Building application with Maven...'
                    sh '''
                        export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
                        export PATH=$JAVA_HOME/bin:$PATH
                        echo "JAVA_HOME: $JAVA_HOME"
                        echo "PATH: $PATH"
                        echo "Java version check:"
                        java --version
                        echo "Maven version check:"
                        mvn --version
                        mvn -B package --file pom.xml -DskipTests
                    '''
                    
                    // Archive artifacts
                    archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: false
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    echo 'Running tests...'
                    sh '''
                        export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
                        export PATH=$JAVA_HOME/bin:$PATH
                        mvn test
                    '''
                }
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    sh """
                        docker build -t ${env.DOCKER_IMAGE}:${env.BUILD_NUMBER} .
                        docker tag ${env.DOCKER_IMAGE}:${env.BUILD_NUMBER} ${env.DOCKER_IMAGE}:latest
                    """
                    echo "Built Docker image: ${env.DOCKER_IMAGE}:${env.BUILD_NUMBER}"
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
                        sh '''
                            echo "Logging into Docker Hub..."
                            echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                        '''
                        sh "docker push ${env.DOCKER_IMAGE}:${env.BUILD_NUMBER}"
                        sh "docker push ${env.DOCKER_IMAGE}:latest"
                        sh 'docker logout'
                    }
                    
                    echo "Successfully pushed ${env.DOCKER_IMAGE}:${env.BUILD_NUMBER}"
                }
            }
        }
        
        stage('Pre-deployment') {
            steps {
                script {
                    echo 'Updating Helm values...'
                    sh """
                        sed -i "s+latest+${env.BUILD_NUMBER}+g" ${env.CHART_PATH}/values.yaml
                    """
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                script {
                    echo 'Deploying to EKS cluster...'
                    
                    // Create namespace if it doesn't exist
                    sh """
                        export KUBECONFIG=/var/lib/jenkins/.kube/config
                        kubectl get namespace ${env.NAMESPACE} || kubectl create namespace ${env.NAMESPACE}
                    """
                    
                    // Create Docker registry secret if it doesn't exist
                    withCredentials([usernamePassword(
                        credentialsId: env.DOCKERHUB_CREDENTIAL, 
                        passwordVariable: 'DOCKER_PASSWORD', 
                        usernameVariable: 'DOCKER_USERNAME'
                    )]) {
                        sh """
                            export KUBECONFIG=/var/lib/jenkins/.kube/config
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
                        export KUBECONFIG=/var/lib/jenkins/.kube/config
                        helm upgrade --install ${env.RELEASE_NAME} ${env.CHART_PATH} \
                          --namespace ${env.NAMESPACE} \
                          --set image.repository=${env.DOCKER_IMAGE} \
                          --set image.tag=${env.BUILD_NUMBER} \
                          --wait --timeout=10m
                    """
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo 'Verifying deployment...'
                    
                    // Check deployment status
                    sh """
                        export KUBECONFIG=/var/lib/jenkins/.kube/config
                        kubectl get deployments -n ${env.NAMESPACE}
                        kubectl get pods -n ${env.NAMESPACE}
                        kubectl get services -n ${env.NAMESPACE}
                    """
                    
                    // Wait for deployment to be ready
                    sh """
                        export KUBECONFIG=/var/lib/jenkins/.kube/config
                        kubectl wait --for=condition=available --timeout=300s deployment/${env.RELEASE_NAME} -n ${env.NAMESPACE}
                    """
                    
                    // Get service endpoint
                    sh """
                        export KUBECONFIG=/var/lib/jenkins/.kube/config
                        echo "=== Service Information ==="
                        kubectl get service ${env.RELEASE_NAME} -n ${env.NAMESPACE} -o wide
                    """
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Clean up Docker images to save space
                sh "docker rmi ${env.DOCKER_IMAGE}:${env.BUILD_NUMBER} || true"
                sh "docker rmi ${env.DOCKER_IMAGE}:latest || true"
                sh "docker system prune -f || true"
                
                echo "Pipeline completed for build ${env.BUILD_NUMBER}"
            }
        }
        
        success {
            script {
                echo "Pipeline completed successfully!"
                echo "Docker image: ${env.DOCKER_IMAGE}:${env.BUILD_NUMBER}"
                echo "Deployed to namespace: ${env.NAMESPACE}"
                
                // Get the service URL
                def serviceInfo = sh(
                    script: """
                        export KUBECONFIG=/var/lib/jenkins/.kube/config
                        kubectl get service ${env.RELEASE_NAME} -n ${env.NAMESPACE} -o wide
                    """,
                    returnStdout: true
                ).trim()
                
                if (serviceInfo) {
                    echo "Service Details: ${serviceInfo}"
                }
            }
        }
        
        failure {
            script {
                echo "Pipeline failed at build ${env.BUILD_NUMBER}"
                echo "Check logs above for error details"
            }
        }
        
        cleanup {
            script {
                // Clean up Docker images to save space
                sh "docker rmi ${env.DOCKER_IMAGE}:${env.BUILD_NUMBER} || true"
                sh "docker system prune -f || true"
            }
            // Clean workspace
            cleanWs()
        }
    }
}
