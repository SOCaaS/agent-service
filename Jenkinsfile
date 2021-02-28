  
pipeline {
    agent any

    stages {
        stage('Install') {
            steps {
                echo 'Installing....'
                sh 'curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose'
                sh 'chmod +x /usr/bin/docker-compose'
                sh '/usr/bin/docker-compose --version'
            }
        }
        // stage('Build') {
        //     steps {
        //         echo 'Building..'
        //         sh 'echo ${BUILD_NUMBER}'
        //         sh 'docker build --network main-overlay -f dockerfile --tag agent-service:${BUILD_NUMBER} .'
        //    }
        // }
        // stage('Test') {
        //     steps {
        //         echo 'Testing..'
        //         sh 'echo ${BUILD_NUMBER}'
        //         sh 'docker run --name test-filebeat-${BUILD_NUMBER} --network main-overlay agent-service:${BUILD_NUMBER} filebeat test config'
        //         sh 'docker rm test-filebeat-${BUILD_NUMBER}'
        //    }
        // }
        // stage('Deploy') {
        //     steps {
        //         echo 'Deploying....'
        //         sh 'TAG=${BUILD_NUMBER} /usr/bin/docker-compose -p "agent" up -d --build'
        //     }
        // }
    }
    post {
        success {
            discordSend description: "Build Success", footer: "Agent Service", link: env.BUILD_URL, result: currentBuild.currentResult, title: JOB_NAME, webhookURL: env.SOCAAS_WEBHOOK
        }
        failure {
            discordSend description: "Build Failed", footer: "Agent Service", link: env.BUILD_URL, result: currentBuild.currentResult, title: JOB_NAME, webhookURL: env.SOCAAS_WEBHOOK
        }
    }
}
