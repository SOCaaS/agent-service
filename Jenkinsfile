  
pipeline {
    agent any
    options {
        ansiColor('xterm')
    }
    stages {
        stage('Install') {
            steps {
                echo 'Installing....'
                sh '''#!/bin/bash
                    if [ ! -f /usr/bin/docker-compose ]; then
                        curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
                        chmod +x /usr/bin/docker-compose
                        /usr/bin/docker-compose --version
                    else 
                        echo "There is noting to be downloaded!"
                    fi
                '''
            }
        }
        stage('Build') {
            steps {
                echo 'Building..'
                sh 'echo ${BUILD_NUMBER}'
                sh 'TAG=${BUILD_NUMBER} /usr/bin/docker-compose -p "agent" build'
           }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
                sh 'echo ${BUILD_NUMBER}'
                sh 'docker run --name test-filebeat-${BUILD_NUMBER} --network main-overlay agent-service:${BUILD_NUMBER} filebeat test config'
                sh 'docker rm test-filebeat-${BUILD_NUMBER}'
           }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
                sh 'TAG=${BUILD_NUMBER} /usr/bin/docker-compose -p "agent" up -d --build'
            }
        }
        stage('Create / Delete') {
            agent {
                docker {
                    image 'base/terraform:latest'
                    args  '-v /root/tfstate:/root/tfstate -v /root/tfvars:/root/tfvars'
                }
            }
            steps {
                echo 'Terraform Creating Server'
                sh 'terraform --version'
                dir("deployment") {
                    sh '''#!/bin/bash
                        terraform init
                        terraform plan  -var-file=/root/tfvars/do-contabo.tfvars
                        terraform apply -var-file=/root/tfvars/do-contabo.tfvars --auto-approve
                        terraform show
                    '''
                }
                echo 'Finished'
            }
        }
        stage('Rebuild') {
            agent {
                docker {
                    image 'base/digitalocean-doctl:latest' 
                    args  '-v /root/tfstate:/root/tfstate -v /home/ezeutno/.ssh/id_rsa:/root/.ssh/id_rsa'
                }
            }
            steps {
                sh 'ls -lah /root/.ssh'
                sh '''#!/bin/bash
                    if [ $(cat /root/tfstate/agent-service-do.tfstate | jq \'.["outputs"]["ids"]["value"][0]\') == null ] 
                    then 
                        echo "The server is turn off!"; 
                    else
                        echo -e "\nDO Re-Build!"
                        doctl compute droplet-action rebuild $(cat /root/tfstate/agent-service-do.tfstate | jq \'.["outputs"]["ids"]["value"][0]\' | sed \'s|"||g\' ) -t ${DIGITALOCEAN_TOKEN} --image ubuntu-20-04-x64 --wait
                        echo -e "\nPing Finished!"
                        ping -c 10 $(cat /root/tfstate/agent-service-do.tfstate | jq \'.["outputs"]["ips"]["value"][0]\' | sed \'s|"||g\' )
                        
                        echo -e "\nCopy data to DigitalOcean!"
                        scp -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa -r $PWD root@$(cat /root/tfstate/agent-service-do.tfstate | jq \'.["outputs"]["ips"]["value"][0]\' | sed \'s|"||g\' ):/root/agent/
                        
                        echo -e "\nStart SSH Script!"
                        ssh -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa root@$(cat /root/tfstate/agent-service-do.tfstate | jq \'.["outputs"]["ips"]["value"][0]\' | sed \'s|"||g\' ) "cd /root/agent/; ./start.sh"
                    fi 
                '''
                echo 'Finished'
            }
        }
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
