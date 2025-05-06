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

        stage('Detect Changes') {
            steps {
                script {
                    def changes = sh(
                        script: 'git diff --name-only HEAD~1 HEAD',
                        returnStdout: true
                    ).trim()

                    echo "Changed Files:\n${changes}"

                    // Backend service flags
                    env.EUREKA_CHANGED = changes.contains('backend/eureka-service/') ? 'true' : 'false'
                    env.API_GATEWAY_CHANGED = changes.contains('backend/api-gateway-service/') ? 'true' : 'false'
                    env.USER_CHANGED = changes.contains('backend/user-service/') ? 'true' : 'false'
                    env.EXAM_CHANGED = changes.contains('backend/exam-service/') ? 'true' : 'false'
                    env.ZUUL_CHANGED = changes.contains('backend/zuul-service/') ? 'true' : 'false'
                    env.ANSWER_CHANGED = changes.contains('backend/answer-service/') ? 'true' : 'false'
                    env.COURSE_CHANGED = changes.contains('backend/course-service/') ? 'true' : 'false'

                    // DB flag: only if docker-compose.yml or db env changes
                    env.DB_CHANGED = changes.contains('backend/docker-compose.yml') ? 'true' : 'false'

                    // Frontend
                    env.FRONTEND_CHANGED = changes.contains('frontend/') ? 'true' : 'false'
                }
            }
        }

        stage('Build & Deploy Backend Services') {
            when {
                expression {
                    return env.EUREKA_CHANGED == 'true' ||
                           env.API_GATEWAY_CHANGED == 'true' ||
                           env.USER_CHANGED == 'true' ||
                           env.EXAM_CHANGED == 'true' ||
                           env.ZUUL_CHANGED == 'true' ||
                           env.ANSWER_CHANGED == 'true' ||
                           env.COURSE_CHANGED == 'true' ||
                           env.DB_CHANGED == 'true'
                }
            }
            steps {
                dir('backend') {
                    script {
                        // Create list of services to build
                        def services = []

                        if (env.EUREKA_CHANGED == 'true') {
                            services = ['eureka-service', 'api-gateway-service', 'user-service', 'exam-service', 'answer-service', 'course-service', 'zuul-service']
                        } else if (env.API_GATEWAY_CHANGED == 'true') {
                            services = ['api-gateway-service', 'user-service', 'exam-service', 'answer-service', 'course-service', 'zuul-service']
                        } else {
                            if (env.USER_CHANGED == 'true') services.add('user-service')
                            if (env.EXAM_CHANGED == 'true') services.add('exam-service')
                            if (env.ZUUL_CHANGED == 'true') services.add('zuul-service')
                            if (env.ANSWER_CHANGED == 'true') services.add('answer-service')
                            if (env.COURSE_CHANGED == 'true') services.add('course-service')
                        }

                        // If DB changed (docker-compose.yml or base infra), add DBs
                        if (env.DB_CHANGED == 'true') {
                            services.add('mysql')
                            services.add('postgres')
                        }

                        echo "Building services: ${services.join(', ')}"

                        sh "docker-compose down || true"
                        sh "docker-compose build ${services.join(' ')}"
                        sh "docker-compose up -d ${services.join(' ')}"
                    }
                }
            }
        }

        stage('Build & Run Frontend') {
            when {
                expression { env.FRONTEND_CHANGED == 'true' }
            }
            steps {
                dir('frontend') {
                    sh "docker build -t ${env.FRONTEND_IMG} ."
                }
                sh "docker rm -f frontend_cont || true"
                sh "docker run -d -p 80:80 --name frontend_cont ${env.FRONTEND_IMG}"
            }
        }
    }
}

