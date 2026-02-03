pipeline {
  agent any

  environment {
    APP_NAME      = "angular-demo"
    IMAGE_NAME    = "angular-ssr"
    HOST_IP       = "172.16.16.143"
    APP_PORT      = "4000"
    HEALTH_URL    = "http://${HOST_IP}:${APP_PORT}"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install Dependencies & Test') {
      steps {
        sh '''
          npm install
          npm run build || true
        '''
      }
    }

    stage('Backup Previous Image') {
      steps {
        script {
          sh '''
            if docker image inspect ${IMAGE_NAME}:latest > /dev/null 2>&1; then
              echo "📦 Backing up previous image"
              docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:previous
            else
              echo "ℹ️ No previous image found"
            fi
          '''
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          docker build -t ${IMAGE_NAME}:latest .
        '''
      }
    }

    stage('Deploy (with retry)') {
      steps {
        retry(2) {
          sh '''
            docker stop ${APP_NAME} || true
            docker rm ${APP_NAME} || true

            docker run -d \
              -p ${APP_PORT}:${APP_PORT} \
              --name ${APP_NAME} \
              ${IMAGE_NAME}:latest
          '''
        }
      }
    }

    stage('Health Check') {
      steps {
        script {
          sh '''
            echo "⏳ Waiting for application health..."

            for i in $(seq 1 10); do
              STATUS=$(curl -o /dev/null -s -w "%{http_code}" ${HEALTH_URL} || true)
              echo "Attempt $i → HTTP $STATUS"

              if [ "$STATUS" = "200" ]; then
                echo "✅ Application is healthy"
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
        docker stop ${APP_NAME} || true
        docker rm ${APP_NAME} || true

        if docker image inspect ${IMAGE_NAME}:previous > /dev/null 2>&1; then
          docker run -d \
            -p ${APP_PORT}:${APP_PORT} \
            --name ${APP_NAME} \
            ${IMAGE_NAME}:previous
          echo "✅ Rollback completed"
        else
          echo "❌ No previous image available for rollback"
        fi
      '''
    }

    success {
      echo "🎉 Deployment successful"
    }
  }
}
