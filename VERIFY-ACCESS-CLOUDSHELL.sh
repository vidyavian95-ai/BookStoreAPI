#!/bin/bash
# Run this in AWS CloudShell to verify demo_devops has access

echo "============================================"
echo "Verifying demo_devops User Access to EKS"
echo "============================================"
echo ""

# 1. Check aws-auth ConfigMap exists
echo "1. Checking aws-auth ConfigMap..."
if kubectl get configmap aws-auth -n kube-system &> /dev/null; then
    echo "✓ aws-auth ConfigMap exists"
else
    echo "✗ aws-auth ConfigMap NOT found"
    exit 1
fi
echo ""

# 2. Display the mapUsers section
echo "2. Checking mapUsers section..."
MAP_USERS=$(kubectl get configmap aws-auth -n kube-system -o jsonpath='{.data.mapUsers}')
if echo "$MAP_USERS" | grep -q "demo_devops"; then
    echo "✓ demo_devops user is mapped"
    echo ""
    echo "Current mapUsers:"
    echo "$MAP_USERS"
else
    echo "✗ demo_devops user NOT found in mapUsers"
    echo ""
    echo "Current mapUsers:"
    echo "$MAP_USERS"
    exit 1
fi
echo ""

# 3. Check full ConfigMap
echo "3. Full aws-auth ConfigMap:"
kubectl get configmap aws-auth -n kube-system -o yaml
echo ""

# 4. Test authentication
echo "4. Testing kubectl authentication..."
if kubectl auth can-i '*' '*' --all-namespaces; then
    echo "✓ Admin access confirmed"
else
    echo "✗ Authentication test failed"
fi
echo ""

echo "============================================"
echo "Verification Complete!"
echo "============================================"
echo ""
echo "If all checks passed, demo_devops has access."
echo "Now test from your local machine or GitHub Actions."
