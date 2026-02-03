def OLD_IMAGE = ""

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
                git branch: 'master', url: 'https://github.com/Lakshmansai1999/angular-ssr.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    OLD_IMAGE = sh(
                        script: "docker images -q ${IMAGE_NAME}:latest || true",
                        returnStdout: true
                    ).trim()

                    sh "docker build -t ${IMAGE_NAME}:latest ."
                }
            }
        }

        stage('Deploy (with retry)') {
            steps {
                retry(2) {
                    sh """
                    docker stop ${APP_NAME} || true
                    docker rm ${APP_NAME} || true

                    docker run -d \
                      -p ${PORT}:${PORT} \
                      --name ${APP_NAME} \
                      ${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    echo "⏳ Waiting for app to start..."
                    sleep 10

                    sh """
                    STATUS=\$(curl -o /dev/null -s -w "%{http_code}" ${HEALTH_URL} || true)

                    echo "Health check HTTP status: \$STATUS"

                    if [ "\$STATUS" != "200" ]; then
                      echo "❌ Health check failed"
                      exit 1
                    fi
                    """
                }
            }
        }
    }

    post {
        failure {
            echo "🚨 Deployment unhealthy. Rolling back..."

            script {
                if (OLD_IMAGE?.trim()) {
                    sh """
                    docker stop ${APP_NAME} || true
                    docker rm ${APP_NAME} || true

                    docker tag ${OLD_IMAGE} ${IMAGE_NAME}:rollback

                    docker run -d \
                      -p ${PORT}:${PORT} \
                      --name ${APP_NAME} \
                      ${IMAGE_NAME}:rollback
                    """
                } else {
                    echo "⚠ No previous image available for rollback"
                }
            }
        }

        success {
            echo "✅ App is healthy. Deployment successful!"
        }
    }
}
