def FRONTEND_CHANGED = false
def BACKEND_CHANGED = false
def EUREKA_CHANGED = false
def GATEWAY_CHANGED = false
def changedMicroservices = [:]

pipeline {
    agent any

    environment {
        FRONTEND_IMG = "frontend:latest"
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/pawanr-98/Dhaninfo.git'
            }
        }

        stage('Detect frontend changes') {
            steps {
                script {
                    def changedFiles = sh(script: 'git diff --name-only HEAD~1 HEAD', returnStdout: true).trim()
                    echo "Changed Files:\n${changedFiles}"

                    if (changedFiles.contains('frontend/')) {
                        FRONTEND_CHANGED = true
                    }
                }
            }
        }

        stage('Build and Deploy Frontend') {
            when {
                expression { FRONTEND_CHANGED }
            }
            steps {
                script {
                    sh "docker build -t ${env.FRONTEND_IMG} ./frontend"
                    sh "docker rm -f frontend_cont || true"
                    sh "docker run -d -p 80:80 --name frontend_cont ${env.FRONTEND_IMG}"
                }
            }
        }

        stage('Detect Changed Backend Services') {
            steps {
                script {
                    def changedFiles = sh(script: "git diff --name-only HEAD~1 HEAD", returnStdout: true).trim()
                    echo "Changed Files:\n${changedFiles}"

                    if (changedFiles.contains("backend/eureka-service/")) {
                        EUREKA_CHANGED = true
                        BACKEND_CHANGED = true
                    }

                    if (changedFiles.contains("backend/api-gateway-service/")) {
                        GATEWAY_CHANGED = true
                        BACKEND_CHANGED = true
                    }

                    def services = ['user-service', 'course-service', 'exam-service', 'answer-service', 'zuul-service']
                    for (svc in services) {
                        if (changedFiles.contains("backend/${svc}/")) {
                            changedMicroservices[svc] = true
                            BACKEND_CHANGED = true
                        }
                    }
                }
            }
        }

        stage('Ensure Base Services Running') {
            when {
                expression { BACKEND_CHANGED }
            }
            steps {
                script {
                    def baseServices = ['mysql', 'postgres', 'eureka-service']
                    for (svc in baseServices) {
                        def running = sh(script: "docker ps -q -f name=${svc}", returnStdout: true).trim()
                        if (!running) {
                            echo "${svc} not running. Starting..."
                            sh "docker-compose -f backend/docker-compose.yml up -d ${svc}"
                        } else {
                            echo "${svc} already running."
                        }
                    }
                }
            }
        }

        stage('Full Backend Rebuild (Eureka changed)') {
            when {
                expression { EUREKA_CHANGED }
            }
            steps {
                script {
                    echo "Rebuilding all backend services due to Eureka change..."
                    sh 'docker-compose -f backend/docker-compose.yml down'
                    sh 'docker-compose -f backend/docker-compose.yml build'
                    sh 'docker-compose -f backend/docker-compose.yml up -d'
                }
            }
        }

        stage('Partial Backend Rebuild (API Gateway changed)') {
            when {
                expression { GATEWAY_CHANGED && !EUREKA_CHANGED }
            }
            steps {
                script {
                    def services = ['user-service', 'course-service', 'exam-service', 'answer-service', 'zuul-service', 'api-gateway-service']
                    for (svc in services) {
                        echo "Rebuilding ${svc}..."
                        sh """
                            docker-compose -f backend/docker-compose.yml stop ${svc} || true
                            docker-compose -f backend/docker-compose.yml rm -f ${svc} || true
                            docker-compose -f backend/docker-compose.yml build ${svc}
                            docker-compose -f backend/docker-compose.yml up -d ${svc}
                        """
                    }
                }
            }
        }

        stage('Selective Microservice Rebuild') {
            when {
                expression { BACKEND_CHANGED && !EUREKA_CHANGED && !GATEWAY_CHANGED }
            }
            steps {
                script {
                    changedMicroservices.each { svc, changed ->
                        echo "Rebuilding ${svc}..."
                        sh """
                            docker-compose -f backend/docker-compose.yml stop ${svc} || true
                            docker-compose -f backend/docker-compose.yml rm -f ${svc} || true
                            docker-compose -f backend/docker-compose.yml build ${svc}
                            docker-compose -f backend/docker-compose.yml up -d ${svc}
                        """
                    }
                }
            }
        }

        stage('No Changes Detected') {
            when {
                expression { !BACKEND_CHANGED }
            }
            steps {
                echo "No changes in backend. Skipping backend rebuild."
            }
        }
    }
}

