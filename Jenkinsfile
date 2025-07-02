pipeline {
    agent none

    environment {
        DOCKER_REPO = 'pdock855' // Docker Hub username 
    }

    stages {

        stage('Git Checkout') {
            agent { label 'built-in' }
            steps {
                //cleanWs()
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/pawanr-98/Dhaninfo.git'
            }
        }

        stage('Frontend: Build & Deploy') {
            agent { label 'built-in' }
            steps {
                script {
                    def serviceName = "frontend"
                    def dockerImageTag = "${DOCKER_REPO}/dr-front:${serviceName}-build-${BUILD_NUMBER}"
                    detectAndDeploy(
                        serviceName: serviceName,
                       // dockerImageTag: "${DOCKER_REPO}/dr-front:${BUILD_NUMBER}",
                        dockerImageTag: dockerImageTag,
                        servicePath: "frontend",
                        k8sFiles: [
                            "k8s-manifests/frontend-deployment.yaml",
                            "k8s-manifests/fend-service.yaml",
                            "k8s-manifests/frontend-ingress.yaml"
                        ]
                    )
                }
            }
        }

        stage('Eureka: Build & Deploy') {
            agent { label 'built-in' }
            steps {
                script {
                    def serviceName = "eureka"
                    def dockerImageTag = "${DOCKER_REPO}/dr-front:${serviceName}-build-${BUILD_NUMBER}"
                    detectAndDeploy(
                        serviceName: serviceName,
                        //dockerImageTag: "${DOCKER_REPO}/dr-front:${BUILD_NUMBER}",
                        dockerImageTag: dockerImageTag,
                        servicePath: "backend/eureka-service",
                        k8sFiles: [
                            "k8s-manifests/eureka-deployment.yaml",
                            "k8s-manifests/eureka-kservice.yaml"
                        ]
                    )
                }
            }
        }
    }
}

//  Reusable deployment logic
def detectAndDeploy(Map args) {
    def serviceName     = args.serviceName
    def dockerImageTag  = args.dockerImageTag
    def servicePath     = args.servicePath
    def k8sFiles        = args.k8sFiles

    def lastCommitFile = "last_deployed/${serviceName}.txt"
    def changed = false

    sh "mkdir -p last_deployed"
    if (!fileExists(lastCommitFile)) {
        sh "git rev-list --max-parents=0 origin/main > ${lastCommitFile}"
    }

    def lastCommit = readFile(lastCommitFile).trim()
    def changeOutput = sh(script: "git diff --name-only ${lastCommit} origin/main -- ${servicePath}/", returnStdout: true).trim()

    if (changeOutput) {
        echo "Changes detected in ${serviceName}"
        changed = true

        withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            sh """
                echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                cd ${servicePath}
                docker build -t ${dockerImageTag} .
                docker push ${dockerImageTag}
                docker logout
            """
        }

        sh "git rev-parse origin/main > ${lastCommitFile}"
    } else {
        echo "No changes in ${serviceName}. Skipping build and deploy."
    }

    if (changed) {
        node('master-node') {
            checkout scm
            k8sFiles.each { file ->
                sh "kubectl apply -f ${file} -n dr"
            }
            sh "kubectl set image deployment/dr-${serviceName} dr-${serviceName}=${dockerImageTag} -n dr"
            sh "kubectl rollout status deployment/dr-${serviceName} -n dr"
        }
    }
}
