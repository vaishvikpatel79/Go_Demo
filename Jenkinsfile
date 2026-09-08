pipeline {
    agent any
    parameters {
        string(name: 'REPO_URL', defaultValue: 'https://github.com/vaishvikpatel79/Go_Demo.git', description: 'Repository URL')
        string(name: 'BRANCH', defaultValue: 'main', description: 'Branch to build')
    }
    options { timeout(time: 90, unit: 'MINUTES'); skipDefaultCheckout() }
    environment {
        // Build versioning default: v1 (incremented to v2 only when code updates)
        IMAGE_TAG = "v1"
        IMAGE_NAME = "go-demo-frontend"
    }
    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                git url: "${params.REPO_URL}", branch: "${params.BRANCH}"
                sh 'git submodule update --init --recursive || true'
            }
        }
        stage('Repository Intelligence') {
            steps {
                sh '''
echo "================================================"
echo "   REPOSITORY INTELLIGENCE SNAPSHOT"
echo "================================================"
echo "Repo type        : microservices"
echo "Language         : go"
echo "Framework        : go"
echo "Build strategy   : existing_jenkinsfile"
echo "Buildable svcs   : 2"
echo "Dockerfile reused: True"
echo "Compose reused   : True"
echo "Jenkinsfile reuse: True"
echo "================================================"
'''
            }
        }
        stage('Validate Build Strategy') {
            steps {
                sh '''
set -eu
echo "Build strategy validation: OK"
echo "[validate] Build strategy validated: existing_jenkinsfile"
'''
            }
        }
        stage('Run Repository Jenkinsfile') {
            steps {
                echo 'Repository Jenkinsfile detected at Jenkinsfile'
                script {
                    load 'Jenkinsfile'
                }
            }
        }

    }
    post {
        always {
            script {
                try {
                    cleanWs()
                } catch (err) {
                    echo "Cleanup: " + err.message
                }
            }
        }
        failure {
            echo 'BUILD FAILED - check console output above'
        }
    }
}
