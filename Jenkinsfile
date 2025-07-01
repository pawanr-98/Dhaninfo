pipeline {
    agent none
    environment {
        DOCKER_IMAGE = "pdock855/dr-front:${BUILD_NUMBER}"
    }
    stages {
        stage('Git Checkout') {
            agent { label 'built-in' }
            steps {
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/pawanr-98/Dhaninfo.git'
                sh 'git fetch origin'
            }
        }

        stage('Frontend Build and Deploy') {
            agent { label 'built-in' }
            steps {
                script {
                    def frontendChanged = false
                    def lastCommitFile = 'last_deployed/frontend.txt'
                    sh 'mkdir -p last_deployed'
                    if (!fileExists(lastCommitFile)) {
                        sh 'git rev-list --max-parents=0 origin/main > ' + lastCommitFile
                    }
                    def lastCommit = readFile(lastCommitFile).trim()
                    def changed = sh(script: "git diff --name-only ${lastCommit} origin/main -- frontend/", returnStdout: true).trim()

                    if (changed) {
                        echo "Changes detected in frontend"
                        frontendChanged = true
                        withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                            sh '''
                                echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                                cd frontend
                                docker build -t $DOCKER_IMAGE .
                                docker push $DOCKER_IMAGE
                                docker logout
                            '''
                        }
                        sh 'git rev-parse origin/main > ' + lastCommitFile
                    } else {
                        echo 'No changes detected in frontend'
                    }

                    if (frontendChanged) {
                        node('master-node') {
                            /*cleanWs()*/
                            checkout scm
                            sh '''
                            kubectl apply -f k8s-manifests/frontend-deployment.yaml -n dr
                            cat k8s-manifests/fend-service.yaml
                            kubectl apply -f k8s-manifests/fend-service.yaml -n dr
                            kubectl apply -f k8s-manifests/frontend-ingress.yaml -n dr
                            kubectl set image deployment/dr-frontend dr-frontend=$DOCKER_IMAGE -n dr
                            kubectl rollout status deployment/dr-frontend -n dr
                            '''
                        }
                    }
                }
            }
        }
    }
}

      /*  stage('Eureka Build') {
            agent { label 'built-in' }
            steps {
                script {
                    def lastCommitFile = 'last_deployed/eureka-service.txt'
                    sh 'mkdir -p last_deployed'
                    if (!fileExists(lastCommitFile)) {
                        sh 'git rev-parse HEAD > ' + lastCommitFile
                    }
                    def lastCommit = readFile(lastCommitFile).trim()
                    def changed = sh(script: "git diff --name-only ${lastCommit}..HEAD backend/eureka-service/", returnStdout: true).trim()

                    if (changed) {
                        echo "Changes detected in eureka-service"
                        env.EUREKA_CHANGES = 'true'
                        withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                            sh '''
                                echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                                cd backend/eureka-service
                                docker build -t $EUREKA_IMAGE .
                                docker push $EUREKA_IMAGE
                                docker logout
                            '''
                        }
                        sh 'git rev-parse HEAD > ' + lastCommitFile
                    } else {
                        echo 'No changes detected in eureka-service'
                    }
                }
            }
        }

        stage('Deploy Eureka') {
            when {
                expression { return env.EUREKA_CHANGES == 'true' }
            }
            agent { label 'master-node' }
            steps {
                sh '''
                kubectl apply -f k8s-manifests/eureka-deployment.yaml -n dr
                kubectl apply -f k8s-manifests/eureka-kservice.yaml -n dr
                kubectl set image deployment/eureka-service eureka-service=$EUREKA_IMAGE -n dr
                kubectl rollout status deployment/eureka-service -n dr
                '''
            }
        }
    }
}*/
