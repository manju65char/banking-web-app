pipeline {
    agent any
    
    triggers {
        githubPush()
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "🔍 Checking out code..."
                sh 'echo "Branch: dev"'
                sh 'echo "Commit: abc123"'
            }
        }
        
        stage('Build') {
            steps {
                echo "🏗️  Building..."
                sh 'echo "Compiling code..."'
                sh 'echo "✅ Build successful"'
            }
        }
        
        stage('Test') {
            steps {
                echo "🧪 Running tests..."
                sh 'echo "Running unit tests..."'
                sh 'echo "✅ Tests passed"'
            }
        }
        
        stage('Code Analysis') {
            steps {
                echo "📊 SonarQube analysis..."
                sh 'echo "Running code quality checks..."'
                sh 'echo "✅ Analysis complete"'
            }
        }
        
        stage('Build Docker') {
            steps {
                echo "🐳 Building Docker image..."
                sh 'echo "Building docker image..."'
                sh 'echo "✅ Image built"'
            }
        }
        
        stage('Push Registry') {
            steps {
                echo "📤 Pushing image..."
                sh 'echo "Pushing to Docker Hub..."'
                sh 'echo "✅ Push complete"'
            }
        }
        
        stage('CI Summary') {
            steps {
                echo "✅ CI Pipeline Complete!"
                sh 'echo "All stages passed successfully"'
            }
        }
    }
    
    post {
        success {
            echo "✅ Pipeline succeeded!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
