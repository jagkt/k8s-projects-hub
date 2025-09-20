# CI/CD pipeline with Jenkins Instalation Steps:
To better understand how these processes were set up, the following will provide a step-by-step guide to the implementation of this project on:
- Builds & tests a Node.js app with Mocha
- Runs SonarQube for code quality checks
- Deploys to your Kubernetes cluster
- Monitors with Prometheus + Grafana

---

## Step 1: Prerequisites
On your Windows 11 host, 
VMware with 3 Alpine Linux VMs

Cluster:
- Master VM → kubeadm, 3GB RAM
- Worker nodes → 4GB each
- Kubernetes installed (kubeadm init, kubeadm join, etc.), kubernetes verion=1.29.0
- kubectl configured on master

On master node
- apk add openjdk16 maven nodejs npm docker git

Install Jenkins:
- apk add jenkins
- rc-update add jenkins
- rc-service jenkins start

install Make:
- apk add make

Access Jenkins via:
- http://<master-ip>:8080

---

## Step 2: Install SonarQube on Kubernetes
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



## Step 3: Install Prometheus + Grafana

Use kube-prometheus-stack (Helm):
```bash
apk add helm

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
#helm install monitoring prometheus-community/kube-prometheus-stack
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
		-f helm/kube-prometheus-values.yaml \
		-n monitoring --create-namespace

kubectl get svc -n monitoring
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```
Now open http://localhost:3000

Default Grafana credentials (from Helm chart):
User: admin
Password: run:

kubectl get secret -n monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

3. Access Prometheus
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
Now open http://localhost:9090

Expose with NodePort or Ingress:
If you don’t want to keep port-forwarding:
kubectl patch svc monitoring-grafana -n monitoring \
  -p '{"spec": {"type": "NodePort"}}'

kubectl patch svc monitoring-kube-prometheus-prometheus -n monitoring \
  -p '{"spec": {"type": "NodePort"}}'

If you want to set a fixed NodePort, edit the service instead of patching:


check the nodeport:
kubectl get svc monitoring-grafana -n monitoring
kubectl get svc monitoring-kube-prometheus-prometheus

This deploys Prometheus, Grafana, Alertmanager.
kubectl edit svc monitoring-kube-prometheus-prometheus -n monitoring
<!-- spec:
  type: NodePort
  ports:
  - name: http-web
    port: 9090
    targetPort: 9090
    nodePort: 30900   #  fixed NodePort -->


---
## Step 4: Node.js Sample App

app.js
```js
const express = require("express");
const app = express();
const port = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.send("Hello from Node.js on Kubernetes!");
});

app.listen(port, () => console.log(`App running on port ${port}`));
```

test/test.js
```js
const assert = require("assert");

describe("Sample Test", () => {
  it("should return true", () => {
    assert.equal(1, 1);
  });
});
```

#### Step 5: Dockerize App

Dockerfile
```bash
FROM node:16
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["node", "app.js"]
```

Build + push to Docker Hub:
```bash
docker build -t <your-dockerhub-user>/nodejs-k8s:latest .
docker push <your-dockerhub-user>/nodejs-k8s:latest
```
#### Step 6: Kubernetes Deployment for Node.js App

node-deploy.yaml
```yaml
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
```

#### Step 7: Jenkins Pipeline

Jenkinsfile
```groovy
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
```
#### Step 8: Monitoring

Access Grafana:
```bash
kubectl port-forward svc/monitoring-grafana 3000:80
```

Login with admin/prom-operator

Add dashboards for Kubernetes + Node.js app
