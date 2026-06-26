# PowerShell script to connect to EKS cluster and view pod logs

$CLUSTER_NAME = "bookstoreapi-eks-cluster"
$REGION = "ap-south-1"
$APP_NAME = "bookstoreapi"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "EKS Cluster Connection & Pod Logs" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Get your IAM identity
Write-Host "Step 1: Getting your IAM identity..." -ForegroundColor Yellow
$USER_ARN = aws sts get-caller-identity --query Arn --output text
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
Write-Host "✓ IAM User ARN: $USER_ARN" -ForegroundColor Green
Write-Host "✓ Account ID: $ACCOUNT_ID" -ForegroundColor Green
Write-Host ""

# Step 2: Check if cluster exists
Write-Host "Step 2: Checking if cluster exists..." -ForegroundColor Yellow
try {
    aws eks describe-cluster --name $CLUSTER_NAME --region $REGION 2>$null | Out-Null
    Write-Host "✓ Cluster '$CLUSTER_NAME' found" -ForegroundColor Green
} catch {
    Write-Host "❌ Cluster '$CLUSTER_NAME' not found" -ForegroundColor Red
    Write-Host "Please create the cluster first using Terraform"
    exit 1
}
Write-Host ""

# Step 3: Add access entry if not exists
Write-Host "Step 3: Ensuring you have access to the cluster..." -ForegroundColor Yellow
try {
    aws eks describe-access-entry --cluster-name $CLUSTER_NAME --principal-arn $USER_ARN --region $REGION 2>$null | Out-Null
    Write-Host "✓ Access entry already exists" -ForegroundColor Green
} catch {
    Write-Host "Creating access entry..."
    aws eks create-access-entry `
        --cluster-name $CLUSTER_NAME `
        --principal-arn $USER_ARN `
        --region $REGION
    
    Write-Host "Associating admin policy..."
    aws eks associate-access-policy `
        --cluster-name $CLUSTER_NAME `
        --principal-arn $USER_ARN `
        --access-scope type=cluster `
        --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy `
        --region $REGION
    
    Write-Host "✓ Access configured" -ForegroundColor Green
}
Write-Host ""

# Step 4: Update kubeconfig
Write-Host "Step 4: Updating kubeconfig..." -ForegroundColor Yellow
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
Write-Host "✓ Kubeconfig updated" -ForegroundColor Green
Write-Host ""

# Step 5: Verify connection
Write-Host "Step 5: Verifying cluster connection..." -ForegroundColor Yellow
Write-Host "Cluster Info:"
kubectl cluster-info
Write-Host ""

Write-Host "Nodes:"
kubectl get nodes
Write-Host ""

# Step 6: Check if pods exist
Write-Host "Step 6: Checking for pods..." -ForegroundColor Yellow
$PODS_JSON = kubectl get pods -l app=$APP_NAME -o json | ConvertFrom-Json
$POD_COUNT = $PODS_JSON.items.Count

if ($POD_COUNT -eq 0) {
    Write-Host "⚠️  No pods found for app: $APP_NAME" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "All pods:"
    kubectl get pods --all-namespaces
    Write-Host ""
    Write-Host "To deploy the application, run:"
    Write-Host "  kubectl apply -f deployment/"
    exit 0
}

Write-Host "✓ Found $POD_COUNT pod(s) for $APP_NAME" -ForegroundColor Green
Write-Host ""

# Step 7: Show pod details
Write-Host "Step 7: Pod Details:" -ForegroundColor Yellow
Write-Host "----------------------------------------"
kubectl get pods -l app=$APP_NAME -o wide
Write-Host ""

# Step 8: Get pod logs
Write-Host "Step 8: Fetching Pod Logs..." -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$POD_NAMES = kubectl get pods -l app=$APP_NAME -o jsonpath='{.items[*].metadata.name}'
$POD_ARRAY = $POD_NAMES -split ' '

foreach ($POD in $POD_ARRAY) {
    if ($POD) {
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "Logs for: $POD" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        
        # Get pod status
        $POD_STATUS = kubectl get pod $POD -o jsonpath='{.status.phase}'
        Write-Host "Status: $POD_STATUS" -ForegroundColor Yellow
        Write-Host ""
        
        # Get logs
        if ($POD_STATUS -eq "Running") {
            Write-Host "Recent logs (last 50 lines):"
            kubectl logs $POD --tail=50
        } elseif ($POD_STATUS -eq "Pending") {
            Write-Host "Pod is still pending. Describing pod:"
            kubectl describe pod $POD
        } else {
            Write-Host "Pod status: $POD_STATUS"
            Write-Host "Attempting to get logs:"
            kubectl logs $POD --tail=50
            Write-Host ""
            Write-Host "Pod description:"
            kubectl describe pod $POD
        }
        
        Write-Host ""
    }
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✓ Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Yellow
Write-Host "  - Follow logs live: kubectl logs -f deployment/$APP_NAME"
Write-Host "  - Get all logs: kubectl logs deployment/$APP_NAME"
Write-Host "  - Describe pod: kubectl describe pod <pod-name>"
Write-Host "  - Get events: kubectl get events --sort-by='.lastTimestamp'"
Write-Host "  - Shell into pod: kubectl exec -it <pod-name> -- /bin/sh"
Write-Host ""
