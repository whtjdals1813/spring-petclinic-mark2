pipeline {
    agent any

    tools {
        maven "M3"
        jdk "JDK21"
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerCredential')
        REGION = "ap-northeast-2"
        AWS_CREDENTIAL_NAME = "AWSCredentials"
    }

    stages {
        stage('Git Clone') {
            steps {
                echo 'Git Clone'
                git url: 'https://github.com/whtjdals1813/spring-petclinic.git', branch: 'main'
            }
            post {
                success {
                    echo 'Git Clone Success'
                }
                failure {
                    echo 'Git Clone Fail'
                }
            }
        }

        stage('Maven Build') {
            steps {
                echo 'Maven Build'
                sh 'mvn -Dmaven.test.failure.ignore=true clean package'
            }
        }

        stage('Docker Image Build') {
            steps {
                echo 'Docker Image Build'
                dir("${env.WORKSPACE}") {
                    sh '''
                        docker build -t spring-petclinic:$BUILD_NUMBER .
                        docker tag spring-petclinic:$BUILD_NUMBER joseongmin/spring-petclinic:latest
                    '''
                }
            }
        }

        stage('Docker Image Push') {
            steps {
                sh '''
                    echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                    docker push joseongmin/spring-petclinic:latest
                '''
            }
        }

        stage('Remove Docker Image') {
            steps {
                sh '''
                    docker rmi spring-petclinic:$BUILD_NUMBER
                    docker rmi joseongmin/spring-petclinic:latest
                '''
            }
        }

        stage('Upload to S3') {
            steps {
                echo "Upload to S3"
                dir("${env.WORKSPACE}") {
                    sh 'zip -r scripts.zip ./scripts appspec.yml'
                    withAWS(region: "${REGION}", credentials: "${AWS_CREDENTIAL_NAME}") {
                        s3Upload(file: "scripts.zip", bucket: "project2-bucket-00")
                    }
                    sh 'rm -rf ./deploy.zip'
                }
            }
        }

        stage('Codedeploy Workload') {
            steps {
                echo "create Codedeploy group"
                withAWS(region: "${REGION}", credentials: "${AWS_CREDENTIAL_NAME}") {
                 // 애플리케이션 없으면 생성
                    sh '''
                        if ! aws deploy get-application --application-name project2-app > /dev/null 2>&1; then
                          echo "Creating CodeDeploy application project2-app..."
                          aws deploy create-application --application-name project2-app --compute-platform Server
                        else
                          echo "CodeDeploy application project2-app already exists. Skipping creation."
                        fi
                    '''
                    sh '''
                        aws deploy create-deployment-group \
                        --application-name project2-app \
                        --auto-scaling-groups project2-autoscaling-group \
                        --deployment-group-name project2-production-in_place-${BUILD_NUMBER} \
                        --deployment-config-name CodeDeployDefault.OneAtATime \
                        --service-role-arn arn:aws:iam::491085389788:role/project2-code-deploy-role
                    '''

                    echo "Codedeploy Workload"

                    sh '''
                        aws deploy create-deployment \
                        --application-name project2-app \
                        --deployment-config-name CodeDeployDefault.OneAtATime \
                        --deployment-group-name project2-production-in_place-${BUILD_NUMBER} \
                        --s3-location bucket=project2-bucket-00,bundleType=zip,key=scripts.zip
                    '''
                    sleep(10)
                }
            }
        }
    }
}
