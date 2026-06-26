#!/bin/bash
# Complete script to connect to EKS cluster and view pod logs

set -e

CLUSTER_NAME="bookstoreapi-eks-cluster"
REGION="ap-south-1"
APP_NAME="bookstoreapi"

echo "=========================================="
echo "EKS Cluster Connection & Pod Logs"
echo "=========================================="
echo ""

# Step 1: Get your IAM identity
echo "Step 1: Getting your IAM identity..."
USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✓ IAM User ARN: $USER_ARN"
echo "✓ Account ID: $ACCOUNT_ID"
echo ""

# Step 2: Check if cluster exists
echo "Step 2: Checking if cluster exists..."
if aws eks describe-cluster --name $CLUSTER_NAME --region $REGION > /dev/null 2>&1; then
    echo "✓ Cluster '$CLUSTER_NAME' found"
else
    echo "❌ Cluster '$CLUSTER_NAME' not found"
    echo "Please create the cluster first using Terraform"
    exit 1
fi
echo ""

# Step 3: Add access entry if not exists
echo "Step 3: Ensuring you have access to the cluster..."
if aws eks describe-access-entry --cluster-name $CLUSTER_NAME --principal-arn "$USER_ARN" --region $REGION > /dev/null 2>&1; then
    echo "✓ Access entry already exists"
else
    echo "Creating access entry..."
    aws eks create-access-entry \
        --cluster-name $CLUSTER_NAME \
        --principal-arn "$USER_ARN" \
        --region $REGION
    
    echo "Associating admin policy..."
    aws eks associate-access-policy \
        --cluster-name $CLUSTER_NAME \
        --principal-arn "$USER_ARN" \
        --access-scope type=cluster \
        --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
        --region $REGION
    
    echo "✓ Access configured"
fi
echo ""

# Step 4: Update kubeconfig
echo "Step 4: Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
echo "✓ Kubeconfig updated"
echo ""

# Step 5: Verify connection
echo "Step 5: Verifying cluster connection..."
echo "Cluster Info:"
kubectl cluster-info
echo ""

echo "Nodes:"
kubectl get nodes
echo ""

# Step 6: Check if pods exist
echo "Step 6: Checking for pods..."
POD_COUNT=$(kubectl get pods -l app=$APP_NAME --no-headers 2>/dev/null | wc -l)

if [ "$POD_COUNT" -eq 0 ]; then
    echo "⚠️  No pods found for app: $APP_NAME"
    echo ""
    echo "All pods:"
    kubectl get pods --all-namespaces
    echo ""
    echo "To deploy the application, run:"
    echo "  kubectl apply -f deployment/"
    exit 0
fi

echo "✓ Found $POD_COUNT pod(s) for $APP_NAME"
echo ""

# Step 7: Show pod details
echo "Step 7: Pod Details:"
echo "----------------------------------------"
kubectl get pods -l app=$APP_NAME -o wide
echo ""

# Step 8: Get pod logs
echo "Step 8: Fetching Pod Logs..."
echo "=========================================="
echo ""

PODS=$(kubectl get pods -l app=$APP_NAME -o jsonpath='{.items[*].metadata.name}')

for POD in $PODS; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Logs for: $POD"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get pod status
    POD_STATUS=$(kubectl get pod $POD -o jsonpath='{.status.phase}')
    echo "Status: $POD_STATUS"
    echo ""
    
    # Get logs
    if [ "$POD_STATUS" = "Running" ]; then
        echo "Recent logs (last 50 lines):"
        kubectl logs $POD --tail=50
    elif [ "$POD_STATUS" = "Pending" ]; then
        echo "Pod is still pending. Describing pod:"
        kubectl describe pod $POD
    else
        echo "Pod status: $POD_STATUS"
        echo "Attempting to get logs:"
        kubectl logs $POD --tail=50 || echo "No logs available"
        echo ""
        echo "Pod description:"
        kubectl describe pod $POD
    fi
    
    echo ""
done

echo "=========================================="
echo "✓ Complete!"
echo "=========================================="
echo ""
echo "Useful commands:"
echo "  - Follow logs live: kubectl logs -f pod/$POD"
echo "  - Get all logs: kubectl logs pod/$POD"
echo "  - Describe pod: kubectl describe pod $POD"
echo "  - Get events: kubectl get events --sort-by='.lastTimestamp'"
echo "  - Shell into pod: kubectl exec -it $POD -- /bin/sh"
echo ""
