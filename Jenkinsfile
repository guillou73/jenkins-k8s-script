pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = "guillou73"
        APP_NAME = "flask-app"
        DB_NAME = "mysql-db"
        VERSION = "${BUILD_NUMBER}"
        DOCKER_CREDENTIALS = credentials('docker-cred')
        KUBECONFIG = credentials('kubeconfig')
        GIT_BRANCH = 'main'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Run Tests') {
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install -r requirements.txt
                    pip install pytest
                    python -m pytest tests/ || true
                '''
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    sh '''
                        docker compose build
                        
                        # Tag the images with build number and latest
                        docker tag ${APP_NAME} ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}
                        docker tag ${APP_NAME} ${DOCKER_REGISTRY}/${APP_NAME}:latest
                        
                        docker tag ${DB_NAME} ${DOCKER_REGISTRY}/${DB_NAME}:${VERSION}
                        docker tag ${DB_NAME} ${DOCKER_REGISTRY}/${DB_NAME}:latest
                    '''
                }
            }
        }
        
        stage('Push Docker Images') {
            steps {
                sh '''
                    echo ${DOCKER_CREDENTIALS_PSW} | docker login -u ${DOCKER_CREDENTIALS_USR} --password-stdin
                    
                    docker push ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}
                    docker push ${DOCKER_REGISTRY}/${APP_NAME}:latest
                    
                    docker push ${DOCKER_REGISTRY}/${DB_NAME}:${VERSION}
                    docker push ${DOCKER_REGISTRY}/${DB_NAME}:latest
                '''
            }
        }
        
        stage('Update Kubernetes Manifests') {
            steps {
                script {
                    sh """
                        # Update image tags in deployment files
                        sed -i 's|image: ${DOCKER_REGISTRY}/${APP_NAME}:.*|image: ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}|' k8s/app-deployment.yaml
                        sed -i 's|image: ${DOCKER_REGISTRY}/${DB_NAME}:.*|image: ${DOCKER_REGISTRY}/${DB_NAME}:${VERSION}|' k8s/db-deployment.yaml
                    """
                }
            }
        }
        
        stage('Deploy Database') {
            steps {
                script {
                    sh '''
                        kubectl apply -f k8s/namespace.yaml
                        kubectl apply -f k8s/db-secret.yaml
                        kubectl apply -f k8s/db-pvc.yaml
                        kubectl apply -f k8s/db-deployment.yaml
                        kubectl apply -f k8s/db-service.yaml
                        
                        # Wait for database to be ready
                        kubectl rollout status deployment/mysql-db -n flask-app
                    '''
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                script {
                    sh '''
                        kubectl apply -f k8s/app-configmap.yaml
                        kubectl apply -f k8s/app-deployment.yaml
                        kubectl apply -f k8s/app-service.yaml
                        
                        # Wait for application to be ready
                        kubectl rollout status deployment/flask-app -n flask-app
                    '''
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    sh '''
                        kubectl get pods -n flask-app
                        kubectl get svc -n flask-app
                    '''
                }
            }
        }
    }
    
    post {
        always {
            sh 'docker logout'
            cleanWs()
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
