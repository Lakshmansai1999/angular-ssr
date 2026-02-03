pipeline {
    agent any

    environment {
        APP_NAME = "angular-demo"
        IMAGE_NAME = "angular-ssr"
        PORT = "4000"
        HEALTH_URL = "http://localhost:4000"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/Lakshmansai1999/angular-ssr.git'
            }
        }

        stage('Backup Previous Image') {
            steps {
                script {
                    sh '''
                    if docker image inspect angular-ssr:latest > /dev/null 2>&1; then
                      echo "Backing up previous image"
                      docker tag angular-ssr:latest angular-ssr:previous
                    else
                      echo "No previous image to back up"
                    fi
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t angular-ssr:latest .'
            }
        }

        stage('Deploy (with retry)') {
            steps {
                retry(2) {
                    sh '''
                    docker stop angular-demo || true
                    docker rm angular-demo || true

                    docker run -d \
                      -p 4000:4000 \
                      --name angular-demo \
                      angular-ssr:latest
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    sh '''
                    echo "⏳ Waiting for app to become healthy..."

                    for i in $(seq 1 10); do
                      STATUS=$(curl -o /dev/null -s -w "%{http_code}" http://localhost:4000 || true)
                      echo "Attempt $i → HTTP $STATUS"

                      if [ "$STATUS" = "200" ]; then
                        echo "✅ App is healthy"
                        exit 0
                      fi

                      sleep 3
                    done

                    echo "❌ Health check failed"
                    exit 1
                    '''
                }
            }
        }
    }

    post {
        failure {
            echo "🚨 Deployment unhealthy. Rolling back..."

            sh '''
            docker stop angular-demo || true
            docker rm angular-demo || true

            if docker image inspect angular-ssr:previous > /dev/null 2>&1; then
              docker run -d \
                -p 4000:4000 \
                --name angular-demo \
                angular-ssr:previous
            else
              echo "⚠ No previous image available for rollback"
            fi
            '''
        }

        success {
            echo "✅ Deployment successful and healthy"
        }
    }
}
