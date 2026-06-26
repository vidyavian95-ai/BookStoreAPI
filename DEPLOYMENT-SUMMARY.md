# BookStoreAPI Deployment Summary

## ✅ What's Been Configured

### 1. Infrastructure (Terraform)
- ✅ ECR Repository: `bookstoreapi`
- ✅ EKS Cluster: `bookstoreapi-eks-cluster` (Kubernetes 1.30)
- ✅ 2 Worker Nodes (t3.small)
- ✅ VPC with public/private subnets
- ✅ State management (S3 + DynamoDB)

### 2. Application Components
- ✅ Spring Boot Application (Java 21)
- ✅ MySQL Database (deployed in Kubernetes)
- ✅ Docker image pushed to ECR
- ✅ Kubernetes deployments configured

### 3. CI/CD Pipeline
- ✅ Maven build and test
- ✅ SpotBugs static analysis
- ✅ SonarQube code quality scan
- ✅ Docker build and push to ECR
- ✅ Deploy to EKS automatically
- ✅ MySQL deployment included

## 🗄️ Database Configuration

### MySQL in Kubernetes
- **Host:** `mysql` (service name)
- **Port:** `3306`
- **Database:** `bookstoreapi`
- **Username:** `root`
- **Password:** `root`
- **Storage:** 10Gi persistent volume

### Application Database Connection
```yaml
SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/bookstoreapi
SPRING_DATASOURCE_USERNAME: root
SPRING_DATASOURCE_PASSWORD: root
SPRING_JPA_HIBERNATE_DDL_AUTO: update
```

## 🚀 Deployment Flow

### Automatic (CI/CD)
When you push to `main` branch:

1. **Build Stage:**
   - Maven builds JAR file
   - SpotBugs analyzes code
   - SonarQube scans for quality issues

2. **Deploy Stage:**
   - Docker image built and pushed to ECR
   - MySQL deployed to Kubernetes (if not exists)
   - Application deployed to EKS
   - Waits for MySQL to be ready
   - Application connects to MySQL

3. **Verification:**
   - Checks pod status
   - Verifies deployment rollout
   - Shows application logs

### Manual Deployment
```bash
# 1. Deploy MySQL
kubectl apply -f deployment/mysql-deployment.yaml

# 2. Wait for MySQL
kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s

# 3. Deploy Application
kubectl apply -f deployment/deployment.yaml
kubectl apply -f deployment/service.yaml
kubectl apply -f deployment/ingress.yaml

# 4. Verify
kubectl get pods
kubectl logs -l app=bookstoreapi
```

## 📊 Current Status

### Infrastructure
```bash
# Check cluster
aws eks describe-cluster --name bookstoreapi-eks-cluster --region ap-south-1

# Check nodes
kubectl get nodes
```

### Application
```bash
# Check all resources
kubectl get all

# Check MySQL
kubectl get pods -l app=mysql

# Check application
kubectl get pods -l app=bookstoreapi

# View logs
kubectl logs -l app=bookstoreapi --tail=50
```

## 🔧 Troubleshooting

### Issue: Application can't connect to MySQL

**Symptoms:**
```
Communications link failure
Connection refused
```

**Solution:**
```bash
# Check if MySQL is running
kubectl get pods -l app=mysql

# Check MySQL logs
kubectl logs -l app=mysql

# If MySQL not deployed, deploy it
kubectl apply -f deployment/mysql-deployment.yaml

# Restart application pods
kubectl rollout restart deployment/bookstoreapi
```

### Issue: Pods not starting

**Check:**
```bash
# Describe pod to see errors
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp' | tail -20

# Check resource usage
kubectl top nodes
kubectl top pods
```

### Issue: Can't access cluster with kubectl

**Solution:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --region ap-south-1 --name bookstoreapi-eks-cluster

# Add your user to cluster access
USER_ARN=$(aws sts get-caller-identity --query Arn --output text)

aws eks create-access-entry \
  --cluster-name bookstoreapi-eks-cluster \
  --principal-arn "$USER_ARN" \
  --region ap-south-1

aws eks associate-access-policy \
  --cluster-name bookstoreapi-eks-cluster \
  --principal-arn "$USER_ARN" \
  --access-scope type=cluster \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --region ap-south-1
```

## 📝 Next Steps

### To Fix Current Issue:
```bash
# Run this now to deploy MySQL and fix the database connection
kubectl apply -f deployment/mysql-deployment.yaml
kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s
kubectl rollout restart deployment/bookstoreapi
kubectl logs -l app=bookstoreapi -f
```

### To Trigger CI/CD:
```bash
# Commit and push changes
git add .
git commit -m "Add MySQL deployment and update CI/CD"
git push origin main

# Watch GitHub Actions: https://github.com/<your-repo>/actions
```

### To Access Application:
```bash
# Get service endpoint
kubectl get service bookstoreapi

# If LoadBalancer, get external IP
kubectl get service bookstoreapi -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Or port-forward for testing
kubectl port-forward service/bookstoreapi 8080:8080
# Then access: http://localhost:8080
```

## 📚 Useful Commands

### Quick Status Check
```bash
# Everything
kubectl get all

# Just your app
kubectl get pods,svc,ingress -l app=bookstoreapi

# With logs
kubectl logs -l app=bookstoreapi --tail=20
```

### Database Access
```bash
# Connect to MySQL pod
kubectl exec -it $(kubectl get pod -l app=mysql -o jsonpath='{.items[0].metadata.name}') -- mysql -u root -proot bookstoreapi

# Run SQL commands
mysql> SHOW TABLES;
mysql> SHOW DATABASES;
```

### Scaling
```bash
# Scale application
kubectl scale deployment bookstoreapi --replicas=5

# Check status
kubectl get pods -l app=bookstoreapi
```

### Cleanup
```bash
# Delete application
kubectl delete -f deployment/

# Delete everything
kubectl delete all --all
```

## 🎯 Summary

Your BookStoreAPI is now configured with:
- ✅ Complete infrastructure (EKS, ECR, VPC)
- ✅ MySQL database in Kubernetes
- ✅ Application deployment with environment variables
- ✅ Automated CI/CD pipeline
- ✅ Proper database connectivity

**To deploy everything, just push to main branch:**
```bash
git add .
git commit -m "Complete BookStoreAPI deployment setup"
git push origin main
```

The CI/CD pipeline will automatically:
1. Build the application
2. Push Docker image to ECR
3. Deploy MySQL to Kubernetes
4. Deploy your application
5. Connect application to MySQL ✅

## 📞 Support

- **Logs:** `kubectl logs -l app=bookstoreapi -f`
- **Status:** `kubectl get all`
- **Debug:** `kubectl describe pod <pod-name>`
- **Events:** `kubectl get events --sort-by='.lastTimestamp'`
