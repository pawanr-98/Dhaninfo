pipeline {
	agent any
	
	environment {
		FRONTEND_IMG = "frontend:latest"
	}
	
	stages {
		stage('git checkout'){
			steps {
				git branch: 'main', url: 'https://github.com/pawanr-98/Dhaninfo.git'	
				}				
			}
		
		stage ('docker compose build'){
			steps {
				dir('backend'){
					script {
						sh 'docker-compose down || true'
						sh 'docker-compose build'
						sh 'docker-compose up -d' 
						}
					}
				}
			}
		stage('Frontend build'){
			steps {
				dir ('frontend'){
					script {
						sh 'docker build -t $FRONTEND_IMG .'
						}
					}
				}
			}
		stage('Run frontend container'){
			steps {
				script{
					sh 'docker run -d -p 80:80 --name frontend_cont $FRONTEND_IMG'
				}
			}	
		}
	}
}	
