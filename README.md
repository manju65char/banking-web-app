# banking-web-app 
Banking domain.
This project front is based on simple HTML, CSS and Angular Js ad Backend is Java Spring Boot.

# Complete CI/CD Setup Guide 

## Phase 1: Ubuntu 24.04 Base Setup

### Step 1: Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2: Install Java (Required for Maven and Jenkins)
```bash
# Install OpenJDK 17 (recommended for Jenkins)
sudo apt install openjdk-17-jdk -y

# Verify installation
java -version
javac -version

# Set JAVA_HOME (add to ~/.bashrc for persistence)
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
source ~/.bashrc
```

### Step 3: Install Maven
```bash
# Install Maven
sudo apt install maven -y

# Verify installation
mvn -version
```

### Step 4: Install Docker
```bash
# Remove old Docker versions
sudo apt-get remove docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt-get install ca-certificates curl gnupg lsb-release -y

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update and install Docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# Add user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify installation
docker --version
docker compose version
```

## Phase 2: AWS Tools Installation

### Step 5: Install AWS CLI
```bash
# Download and install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install

# Clean up
rm -rf aws awscliv2.zip

# Verify installation
aws --version
```

### Step 6: Install kubectl
```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Clean up
rm kubectl

# Verify installation
kubectl version --client
```

### Step 7: Install eksctl
```bash
# Download and install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Verify installation
eksctl version
```

### Step 8: Install Helm
```bash
# Download and install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version
```

### Step 9: Configure AWS Credentials
```bash
# Configure AWS CLI with your credentials
aws configure

# Enter your:
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]  
# Default region name: us-west-2 (or your preferred region)
# Default output format: json
```

## Phase 3: Jenkins Installation and Configuration

### Step 10: Install Jenkins
```bash
# Add Jenkins repository key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update and install Jenkins
sudo apt-get update
sudo apt-get install jenkins -y

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check Jenkins status
sudo systemctl status jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Step 11: Initial Jenkins Web Setup
1. **Access Jenkins**: Open `http://your-server-ip:8080`
2. **Unlock Jenkins**: Use the initial admin password from above
3. **Install suggested plugins**
4. **Create admin user**

### Step 12: Configure Jenkins Tools
1. Go to **Manage Jenkins** → **Global Tool Configuration**

#### JDK Configuration
- Name: `jdk-17`
- JAVA_HOME: `/usr/lib/jvm/java-17-openjdk-amd64`
- Uncheck: "Install automatically"

#### Maven Configuration  
- Name: `maven-3.9`
- MAVEN_HOME: `/usr/share/maven`
- Uncheck: "Install automatically"

#### Docker Configuration
- Name: `Docker`
- Install automatically: ✓
- Version: Latest

### Step 13: Install Required Jenkins Plugins
Go to **Manage Jenkins** → **Manage Plugins** and install:
- Docker Pipeline Plugin
- Kubernetes CLI Plugin  
- AWS Steps Plugin
- Git Plugin
- Maven Integration Plugin
- Stage view
- Blue Ocean (optional)

### Step 14: Configure Jenkins for Docker Access
```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

## Phase 4: EKS Cluster Setup

### Step 15: Create EKS Cluster
```bash
# Create EKS cluster (this takes 15-20 minutes)
eksctl create cluster \
  --name banking-web-app-cluster \
  --region us-west-2 \
  --nodegroup-name banking-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed

# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name banking-web-app-cluster

# Verify cluster access
kubectl get nodes
kubectl get svc
```

### Step 16: Create Kubernetes Namespace
```bash
# Create namespace for your application
kubectl create namespace banking-app

# Set as default namespace (optional)
kubectl config set-context --current --namespace=banking-app

# Verify namespace
kubectl get namespaces
```

### Step 17: Label Nodes (if needed)
```bash
# Label both nodes with role=user
kubectl label nodes ip-192-168-46-20.us-west-2.compute.internal role=user
kubectl label nodes ip-192-168-86-151.us-west-2.compute.internal role=user

# Verify the labels
kubectl get nodes --show-labels | grep role=user
```

## Phase 5: Jenkins and Kubernetes Integration

### Step 18: Configure Jenkins Access to Kubernetes
```bash
# 1. Copy kubeconfig for Jenkins
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/config
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
sudo chmod 600 /var/lib/jenkins/.kube/config

# 2. Copy AWS credentials for Jenkins  
sudo mkdir -p /var/lib/jenkins/.aws
sudo cp ~/.aws/credentials /var/lib/jenkins/.aws/
sudo cp ~/.aws/config /var/lib/jenkins/.aws/
sudo chown -R jenkins:jenkins /var/lib/jenkins/.aws
sudo chmod 600 /var/lib/jenkins/.aws/*

# 3. Restart Jenkins to apply changes
sudo systemctl daemon-reload  
sudo systemctl restart jenkins
```

### Step 19: Create Kubernetes Secrets
```bash
# Create Docker registry secret in Kubernetes
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=manjunathachar \
  --docker-password=dockerhub_token \
  --docker-email=manju65char@gmail.com \
  -n banking-app

# Verify secret creation
kubectl get secrets -n banking-app
```

### Step 20: Create Service Account for Jenkins
```bash
# Create service account for Jenkins in EKS
kubectl create serviceaccount jenkins-sa -n banking-app

# Create ClusterRoleBinding for deployment permissions
kubectl create clusterrolebinding jenkins-sa-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=banking-app:jenkins-sa

# Verify service account
kubectl get serviceaccounts -n banking-app
```

## Phase 6: Jenkins Credentials Configuration

### Step 21: Configure Credentials in Jenkins
Go to **Manage Jenkins** → **Manage Credentials** → **System** → **Global credentials**

#### 1. GitHub PAT
- Kind: `Username with password`
- Username: `manju65char`
- Password: `PAT`
- ID: `github-pat`
- Description: `GitHub Personal Access Token`

#### 2. Docker Hub Credentials
- Kind: `Username with password`
- Username: `manjunathachar`
- Password: `dockerhub token`
- ID: `dockerhub-creds`
- Description: `Docker Hub Credentials`

## Phase 7: SSL/TLS and Ingress Setup

### Step 22: Create Self-Signed Certificate
```bash
# Create self-signed cert for immediate use
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=bank.manjublinkng.xyz/O=banking-app"

# Create TLS secret in Kubernetes
kubectl create secret tls banking-app-tls \
  --cert=tls.crt --key=tls.key \
  -n banking-app

# Clean up certificate files
rm tls.key tls.crt

# Verify TLS secret
kubectl get secrets -n banking-app
```

### Step 23: Install Kong Ingress Controller
```bash
# Create Kong namespace
kubectl create namespace kong

# Add Kong Helm repository
helm repo add kong https://charts.konghq.com
helm repo update

# Install Kong (you'll need to create kong-eks-values.yaml first)
helm install kong kong/kong \
  -f kong-eks-values.yaml \
  -n kong \
  --wait

# Check Kong pods
kubectl get pods -n kong
kubectl get svc -n kong
```

### Step 24: Install Metrics Server (Optional)
```bash
# Install metrics-server for monitoring
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify installation
kubectl get pods -n kube-system | grep metrics-server
```

## Phase 8: Testing and Verification

### Step 25: Create Test Pipeline in Jenkins
Create a new Pipeline job with this script to verify all integrations:

```groovy
pipeline {
    agent any
    
    stages {
        stage('Test Tools') {
            steps {
                script {
                    sh 'java -version'
                    sh 'mvn -version'
                    sh 'docker --version'
                    sh 'kubectl version --client'
                    sh 'aws --version'
                }
            }
        }
        
        stage('Test Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                        sh 'docker logout'
                    }
                }
            }
        }
        
        stage('Test Kubernetes') {
            steps {
                script {
                    sh 'kubectl get nodes'
                    sh 'kubectl get namespaces'
                    sh 'kubectl get pods -n banking-app'
                }
            }
        }
        
        stage('Test AWS') {
            steps {
                script {
                    sh 'aws sts get-caller-identity'
                    sh 'aws eks describe-cluster --name banking-web-app-cluster --region us-west-2'
                }
            }
        }
    }
}
```

### Step 26: Configure GitHub Repository Integration
1. Create new **Pipeline** job in Jenkins
2. **Pipeline** section:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: `https://github.com/manju65char/banking-web-app.git`
   - Credentials: Select your GitHub PAT credential
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`

### Step 27: Final Verification Commands
```bash
# Verify cluster health
kubectl get nodes
kubectl get pods -A
kubectl top nodes (if metrics-server is installed)

# Check all namespaces
kubectl get all -n banking-app
kubectl get all -n kong

# Test connectivity
kubectl cluster-info
```

## Phase 9: Security and Firewall Configuration

### Step 28: Configure Firewall (if UFW is enabled)
```bash
# Allow necessary ports
sudo ufw allow 8080    # Jenkins
sudo ufw allow 22      # SSH
sudo ufw allow 80      # HTTP
sudo ufw allow 443     # HTTPS

# Check status
sudo ufw status

# Enable firewall (if not already enabled)
# sudo ufw enable
```

### Step 29: Optional GitHub Webhook Configuration
1. Go to your GitHub repository: `https://github.com/manju65char/banking-web-app`
2. Navigate to **Settings** → **Webhooks**
3. Click **Add webhook**
4. Payload URL: `http://your-jenkins-server:8080/github-webhook/`
5. Content type: `application/json`
6. Events: Select "Just the push event"

## Cleanup Commands (When Needed)

### Complete Environment Cleanup
```bash
# Delete EKS cluster
eksctl delete cluster --name banking-web-app-cluster --region us-west-2

# Remove Docker images
docker system prune -a

# Stop Jenkins
sudo systemctl stop jenkins

# Remove Jenkins (if needed)
# sudo apt-get remove --purge jenkins
```

## Troubleshooting Common Issues

### Jenkins can't access Docker:
```bash
groups jenkins
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### kubectl not working in Jenkins:
```bash
# Verify kubeconfig permissions
ls -la /var/lib/jenkins/.kube/
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
```

### AWS CLI issues:
```bash
# Verify AWS credentials
ls -la /var/lib/jenkins/.aws/
aws sts get-caller-identity
```

---

**Note**: This guide assumes you have:
- Ubuntu 24.04 server with sudo access
- AWS account with appropriate permissions
- GitHub repository access
- Docker Hub account
- Domain name for ingress (bank.manjublinkng.xyz)

Follow each step sequentially for a complete CI/CD pipeline setup.
