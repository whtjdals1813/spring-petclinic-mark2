pipeline {
    agent { label 'jenkins-jenkins-agent' }

    tools {
        maven "M3"
        jdk "JDK21"
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerCredential')
        KUBECONFIG_CREDENTIALS = credentials('kubeconfig') // 쿠버네티스 인증 정보
        DOCKER_IMAGE = "joseongmin/spring-petclinic"
    }

    stages {
        stage('Git Clone') {
            steps {
                echo 'Git Clone'
                git url: 'https://github.com/whtjdals1813/spring-petclinic-mark2.git', branch: 'master'
            }
        }

        stage('Maven Build') {
            steps {
                echo 'Maven Build'
                sh 'mvn -Dmaven.test.failure.ignore=true clean package'
            }
        }

        stage('Docker Image Build & Push') {
            steps {
                echo 'Docker Image Build & Push'
                sh '''
                    docker build -t $DOCKER_IMAGE:$BUILD_NUMBER .
                    docker tag $DOCKER_IMAGE:$BUILD_NUMBER $DOCKER_IMAGE:latest

                    echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                    docker push $DOCKER_IMAGE:$BUILD_NUMBER
                    docker push $DOCKER_IMAGE:latest
                '''
            }
        }

        stage('Kubernetes Deploy') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                    sh '''
                        export KUBECONFIG=$KUBECONFIG_FILE

                        # 이미지 버전을 Deployment에 반영
                        sed "s|<IMAGE_TAG>|$DOCKER_IMAGE:$BUILD_NUMBER|g" k8s/deployment.yaml > k8s/deployment-gen.yaml
                        
                        kubectl apply -f k8s/deployment-gen.yaml
                    '''
                }
            }
        }

        stage('Cleanup Docker Images') {
            steps {
                sh '''
                    docker rmi $DOCKER_IMAGE:$BUILD_NUMBER || true
                    docker rmi $DOCKER_IMAGE:latest || true
                '''
            }
        }
    }
}
