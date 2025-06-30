pipeline {
    agent none 
    environment {
        DOCKER_IMAGE= "pdock855/dr-front:${BUILD_NUMBER}"
        EUREKA_IMAGE= "pdock855/eureka:${BUILD_NUMBER}"
    }

    stages {
        stage('Git Checkout'){
            agent { label 'built-in' }
            steps {
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/pawanr-98/Dhaninfo.git'
            }
        }

    stage('Frontend Build') {
        agent { label 'built-in' }
        steps {
            script {
                def lastCommitFile = 'last_deployed/frontend.txt'
                sh 'mkdir -p last_deployed'
                if (!fileExists(lastCommitFile)) {
                    sh 'git rev-parse HEAD > ' + lastCommitFile
                }
                def lastCommit = readFile(lastCommitFile).trim()
                def changed = sh(script: "git diff --name-only ${lastCommit}..HEAD frontend/", returnStdout: true).trim()

                if (changed) {
                    echo "Changes detected in frontend"
                    withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                            cd frontend
                            docker build -t $DOCKER_IMAGE .
                            docker push $DOCKER_IMAGE
                            docker logout
                        '''
                    }
                    sh 'git rev-parse HEAD > ' + lastCommitFile
                    buildFrontend = true
                } else {
                    echo 'No changes detected in frontend'
                }
            }  
        }
    }

    stage('Deploy Frontend') {
        when {
            expression { return buildFrontend }
        }
        agent { label 'master-node' }
        steps {
            sh '''
            kubectl apply -f k8s-manifests/frontend-deployment.yaml -n dr
            kubectl apply -f k8s-manifests/frontend-service.yaml -n dr
            kubectl apply -f k8s-manifests/frontend-ingress.yaml -n dr
            kubectl set image deployment/dr-frontend dr-frontend=$DOCKER_IMAGE -n dr
            kubectl rollout status deployment/dr-frontend -n dr
            '''
        }
    }

        stage('Eureka Build and Deploy') {
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
                        buildEureka = true
                        
                        }
                    } else {
                        echo 'No changes detected in eureka-service'
                }
            }
        }

        stage('Deploy eureka'){
            when { 
                expression { return buildEureka }
            }
            agent {'master-node'}
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
}

