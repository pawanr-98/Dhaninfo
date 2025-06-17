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
		stage('Check frontend changes'){
			steps{
				script{
					def changedFiles = sh(
						script: 'git diff --name-only HEAD~1 HEAD',
						returnStdout: true
					).trim()
					
					echo "Changed Files:\n${changedFiles}"
					
					if(changedFiles.contains('frontend/')){
						echo "frontend has changed"
						env.FRONTEND_CHANGED = 'true'
					} else {
						echo "No changes in frontend"
						env.FRONTEND_CHANGED = 'false'
					} 
				}
			}
		}
		
		/*stage ('docker compose build'){
			steps {
				dir('backend'){
					script {
						sh 'docker-compose down || true'
						sh 'docker-compose build'
						sh 'docker-compose up -d' 
						}
					}
				}
			}*/
		stage('Frontend build'){
			when {
				expression { env.FRONTEND_CHANGED == 'true' }
			}
			steps {
				dir ('frontend'){
					script {
						sh """#!/bin/bash
						docker build -t ${env.FRONTEND_IMG} .
						"""
						}
					}
				}
			}
		stage('Run frontend container'){
			when {
				expression { env.FRONTEND_CHANGED == 'true' }
			}
			steps {
				script{
					sh """#!/bin/bash
     					docker rm -f frontend_cont || true
					docker run -d -p 8090:8090 --name frontend_cont ${env.FRONTEND_IMG}
     					"""
				}
			}	
		}
	}
}	
