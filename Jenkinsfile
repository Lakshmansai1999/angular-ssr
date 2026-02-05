pipeline {
    agent any

    environment {
        IMAGE_NAME = "angular-ssr"
        APP_PORT = "4000"
        BLUE_PORT = "4001"
        GREEN_PORT = "4002"
        SERVER_IP = "172.16.16.143"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                sh '''
                npm install
                npm run build
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:latest .'
            }
        }

        stage('Detect Active Color') {
            steps {
                script {
                    def blueRunning = sh(
                        script: "docker ps --filter name=angular-demo-blue --format '{{.Names}}'",
                        returnStdout: true
                    ).trim()

                    env.ACTIVE_COLOR = blueRunning ? "blue" : "green"
                    env.NEW_COLOR = (env.ACTIVE_COLOR == "blue") ? "green" : "blue"

                    echo "🟦 Active: ${env.ACTIVE_COLOR}"
                    echo "🟩 New: ${env.NEW_COLOR}"
                }
            }
        }

        stage('Deploy New Version') {
            steps {
                retry(2) {
                    sh '''
                    docker rm -f angular-demo-${NEW_COLOR} || true

                    PORT=$([ "${NEW_COLOR}" = "blue" ] && echo ${BLUE_PORT} || echo ${GREEN_PORT})

                    docker run -d \
                      -p ${PORT}:4000 \
                      --name angular-demo-${NEW_COLOR} \
                      ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    sh '''
                    echo "⏳ Waiting for health..."
                    PORT=$([ "${NEW_COLOR}" = "blue" ] && echo ${BLUE_PORT} || echo ${GREEN_PORT})

                    for i in {1..10}; do
                      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://${SERVER_IP}:${PORT} || true)
                      echo "Attempt $i → HTTP $STATUS"
                      [ "$STATUS" = "200" ] && exit 0
                      sleep 3
                    done

                    echo "❌ Health check failed"
                    exit 1
                    '''
                }
            }
        }

        stage('Switch Traffic') {
            steps {
                sh '''
                echo "🔁 Switching traffic..."

                docker rm -f angular-demo || true

                PORT=$([ "${NEW_COLOR}" = "blue" ] && echo ${BLUE_PORT} || echo ${GREEN_PORT})

                docker run -d \
                  -p ${APP_PORT}:4000 \
                  --name angular-demo \
                  --network host \
                  ${IMAGE_NAME}:latest

                docker rm -f angular-demo-${ACTIVE_COLOR} || true
                '''
            }
        }
    }

    post {
        failure {
            echo "🚨 Deployment failed. Keeping previous version running."
        }

        success {
            echo "✅ Blue/Green deployment successful!"
        }
    }
}
