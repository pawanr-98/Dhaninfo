pipeline {
    agent any

    environment {
	FRONTEND_IMG = "frontend:latest"
        BACKEND_CHANGED = 'false'
        EUREKA_CHANGED = 'false'
        GATEWAY_CHANGED = 'false'
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/pawanr-98/Dhaninfo.git'
            }
        }
		
		stage('Detect frontend changes'){
			steps {
				script {
					def changedFiles = sh(
						script: 'git diff --name-only HEAD~1 HEAD',
						returnStdout:true
						).trim()
					echo "changed Files:\n${changedFiles}"
					
					if (changedFiles.contains('frontend/')){
						env.FRONTEND_CHANGED = 'true'
					} else {
						env.FRONTEND_CHANGED = 'false'
					}
				}
			}
		}
		
		stage('Build and Deploy Frontend'){
			when {
				expression { env.FRONTEND_CHANGED == 'true' } 
			}	
			steps{
				script {
					sh 'docker build -t ${env.FRONTEND_IMG} .'
					sh 'docker rm -f frontend_cont'
					sh 'docker run -d -p 80:80 --name frontend_cont ${env.FRONTEND_IMG}'
				}		
			}
		}
		
        stage('Detect Changed Services') {
            steps {
                script {
                    def changedFiles = sh(script: "git diff --name-only HEAD~1 HEAD", returnStdout: true).trim()
                    echo "Changed Files:\n${changedFiles}"

                    if (changedFiles.contains('backend/eureka-service/')) {
                        env.EUREKA_CHANGED = 'true'
                        env.BACKEND_CHANGED = 'true'
                    }

                    if (changedFiles.contains('backend/api-gateway-service/')) {
                        env.GATEWAY_CHANGED = 'true'
                        env.BACKEND_CHANGED = 'true'
                    }

                    def services = ['user-service', 'course-service', 'exam-service', 'answer-service', 'zuul-service']
                    for (svc in services) {
                        if (changedFiles.contains("backend/${svc}/")) {
                            env."${svc.replace('-', '_').toUpperCase()}_CHANGED" = 'true'
                            env.BACKEND_CHANGED = 'true'
                        }
                    }
                }
            }
        }

        stage('Ensure Base Services Running') {
            when {
                expression { env.BACKEND_CHANGED == 'true' }
            }
            steps {
                script {
                    def baseServices = ['mysql', 'postgres', 'eureka-service']
                    for (svc in baseServices) {
                        def running = sh(script: "docker ps -q -f name=${svc}", returnStdout: true).trim()
                        if (running == '') {
                            echo "${svc} not running. Starting..."
                            sh "docker-compose -f backend/docker-compose.yml up -d ${svc}"
                        } else {
                            echo "${svc} is already running."
                        }
                    }
                }
            }
        }

        stage('Full Backend Rebuild (Eureka changed)') {
            when {
                expression { env.EUREKA_CHANGED == 'true' }
            }
            steps {
                script {
                    echo "Rebuilding ALL services due to Eureka change..."
                    sh 'docker-compose -f backend/docker-compose.yml down'
                    sh 'docker-compose -f backend/docker-compose.yml build'
                    sh 'docker-compose -f backend/docker-compose.yml up -d'
                }
            }
        }

        stage('Partial Backend Rebuild (API Gateway changed)') {
            when {
                expression { env.GATEWAY_CHANGED == 'true' && env.EUREKA_CHANGED != 'true' }
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
                expression { env.EUREKA_CHANGED != 'true' && env.GATEWAY_CHANGED != 'true' }
            }
            steps {
                script {
                    def services = ['user-service', 'course-service', 'exam-service', 'answer-service', 'zuul-service', 'api-gateway-service']
                    for (svc in services) {
                        def envVar = "${svc.replace('-', '_').toUpperCase()}_CHANGED"
                        if (env[envVar] == 'true') {
                            echo "Rebuilding ${svc}..."
                            sh """
                                docker-compose -f backend/docker-compose.yml stop ${svc} || true
                                docker-compose -f backend/docker-compose.yml rm -f ${svc} || true
                                docker-compose -f backend/docker-compose.yml build ${svc}
                                docker-compose -f backend/docker-compose.yml up -d ${svc}
                            """
                        } else {
                            echo "${svc} not changed. Skipping..."
                        }
                    }
                }
            }
        }

        stage('No Changes Detected') {
            when {
                expression {
                    return env.BACKEND_CHANGED != 'true'
                }
            }
            steps {
                echo "No changes detected in backend. Skipping build and deployment."
            }
        }
    }
}

