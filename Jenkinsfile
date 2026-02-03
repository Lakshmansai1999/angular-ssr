pipeline {
    agent any

    environment {
        APP_NAME = "angular-demo"
        IMAGE_NAME = "angular-ssr"
        PORT = "4000"
        OLD_IMAGE = ""
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Lakshmansai1999/angular-ssr.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    OLD_IMAGE = sh(
                        script: "docker images -q ${IMAGE_NAME}:latest || true",
                        returnStdout: true
                    ).trim()

                    sh """
                    docker build -t ${IMAGE_NAME}:latest .
                    """
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
    }

    post {
        failure {
            echo "❌ Deployment failed. Rolling back..."

            script {
                if (OLD_IMAGE) {
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
                    echo "⚠ No previous image available"
                }
            }
        }

        success {
            echo "✅ Deployment successful"
        }
    }
}
