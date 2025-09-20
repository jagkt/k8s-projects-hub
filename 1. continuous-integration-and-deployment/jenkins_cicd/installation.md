### CI/CD pipeline using Jenkins that:

_ Builds & tests a Node.js app with Mocha

_ Runs SonarQube for code quality checks

_ Deploys to your Kubernetes cluster

_Monitors with Prometheus + Grafana

#### Step 1: Prerequisites
On your Windows 11 host

VMware with 3 Alpine Linux VMs

Cluster:

Master VM → kubeadm, 2GB RAM

Worker nodes → 4GB each

Kubernetes installed (kubeadm init, kubeadm join, etc.)

kubectl configured on master

On master node
apk add openjdk11 maven nodejs npm docker git


Install Jenkins:

apk add jenkins
rc-update add jenkins
rc-service jenkins start

install
apk add make


Access Jenkins via:
http://<master-ip>:8080

#### Step 2: Install SonarQube on Kubernetes
##### sonar-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sonarqube
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sonarqube
  template:
    metadata:
      labels:
        app: sonarqube
    spec:
      containers:
        - name: sonarqube
          image: sonarqube:latest
          ports:
            - containerPort: 9000
---
apiVersion: v1
kind: Service
metadata:
  name: sonarqube
spec:
  selector:
    app: sonarqube
  ports:
    - port: 9000
      targetPort: 9000


Apply it:

kubectl apply -f sonar-deployment.yaml

Expose via NodePort if you want external access.



#### Step 3: Install Prometheus + Grafana

Use kube-prometheus-stack (Helm):

apk add helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack


This deploys Prometheus, Grafana, Alertmanager.


#### Step 4: Node.js Sample App

app.js

const express = require("express");
const app = express();
const port = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.send("Hello from Node.js on Kubernetes!");
});

app.listen(port, () => console.log(`App running on port ${port}`));


test/test.js

const assert = require("assert");

describe("Sample Test", () => {
  it("should return true", () => {
    assert.equal(1, 1);
  });
});


#### Step 5: Dockerize App

Dockerfile

FROM node:16
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["node", "app.js"]


Build + push to Docker Hub:

docker build -t <your-dockerhub-user>/nodejs-k8s:latest .
docker push <your-dockerhub-user>/nodejs-k8s:latest

#### Step 6: Kubernetes Deployment for Node.js App

node-deploy.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nodejs-app
  template:
    metadata:
      labels:
        app: nodejs-app
    spec:
      containers:
        - name: nodejs
          image: <your-dockerhub-user>/nodejs-k8s:latest
          ports:
            - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: nodejs-service
spec:
  selector:
    app: nodejs-app
  ports:
    - port: 80
      targetPort: 3000
  type: NodePort


#### Step 7: Jenkins Pipeline

Jenkinsfile

pipeline {
    agent any
    tools {
        nodejs "NodeJS"
    }
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/<your-repo>/nodejs-k8s-app.git'
            }
        }
        stage('Unit Tests') {
            steps {
                sh 'npm install'
                sh 'npm test'
            }
        }
        stage('Code Quality') {
            steps {
                sh 'sonar-scanner \
                    -Dsonar.projectKey=nodejs-app \
                    -Dsonar.sources=. \
                    -Dsonar.host.url=http://sonarqube:9000 \
                    -Dsonar.login=<sonar-token>'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t <your-dockerhub-user>/nodejs-k8s:latest .'
            }
        }
        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh 'echo $PASS | docker login -u $USER --password-stdin'
                    sh 'docker push <your-dockerhub-user>/nodejs-k8s:latest'
                }
            }
        }
        stage('Deploy to K8s') {
            steps {
                sh 'kubectl apply -f k8s/node-deploy.yaml'
            }
        }
    }
    post {
        success {
            echo "Deployment successful!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}

#### Step 8: Monitoring

Access Grafana:

kubectl port-forward svc/monitoring-grafana 3000:80


Login with admin/prom-operator

Add dashboards for Kubernetes + Node.js app
