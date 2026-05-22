pipeline {
    agent any

    environment {
        APP_NAME = "bookstore-api"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                url: 'https://github.com/Devops12389/Demo_Devops.git'
            }
        }

        stage('Build Application') {
            steps {
                bat '"C:\\Program Files\\maven\\apache-maven-3.9.15\\bin\\mvn.cmd" clean package -DskipTests'
            }
        }

       // stage('Run Unit Tests') {
       //     steps {
       //         bat 'mvn test'
         //   }
       // }

        stage('Archive JAR') {
            steps {
                archiveArtifacts artifacts: '*.java', fingerprint: true
            }
        }
    }

    post {

        success {
            echo 'Build completed successfully'
        }

        failure {
            echo 'Build failed'
        }
    }
}
