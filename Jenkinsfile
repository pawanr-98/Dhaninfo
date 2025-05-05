pipeline {
	agent any
	
	
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
		}
	}
