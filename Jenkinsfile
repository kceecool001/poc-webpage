pipeline {
  agent any

  parameters {
    string(name: 'COMMIT_SHA', defaultValue: 'main', description: 'Commit to build (passed by Azure DevOps)')
  }

  environment {
    IMAGE_NAME = 'poc-web'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        sh "git checkout ${params.COMMIT_SHA}"
      }
    }

    stage('Unit test') {
      steps {
        sh 'sh ./test.sh'
      }
    }

    stage('Build image') {
      steps {
        sh "docker build -t ${IMAGE_NAME}:${params.COMMIT_SHA} ."
      }
    }

    stage('Export image') {
      steps {
        sh "docker save ${IMAGE_NAME}:${params.COMMIT_SHA} -o ${IMAGE_NAME}.tar"
        archiveArtifacts artifacts: "${IMAGE_NAME}.tar", fingerprint: true
      }
    }
  }

  post {
    always {
      sh "docker rmi ${IMAGE_NAME}:${params.COMMIT_SHA} || true"
      cleanWs()
    }
  }
}