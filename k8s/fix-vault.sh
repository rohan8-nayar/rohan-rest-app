#!/bin/bash

# Fix Vault port binding issue
# This script completely redeploys Vault to clear the port binding issue

set -e

echo "🔧 Fixing Vault Port Binding Issue"
echo "=================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Check current pod status
echo "🔍 Step 1: Checking current Vault pod status..."
kubectl get pods -n vault -l app=vault
echo ""

# Step 2: Scale down the deployment to 0
echo "⬇️  Step 2: Scaling down Vault deployment to 0 replicas..."
kubectl scale deployment vault -n vault --replicas=0
echo -e "${GREEN}✅ Deployment scaled down${NC}"
echo ""

# Step 3: Wait for pod to be terminated
echo "⏳ Step 3: Waiting for pod to be fully terminated..."
kubectl wait --for=delete pod -l app=vault -n vault --timeout=60s 2>/dev/null || true
sleep 5
echo -e "${GREEN}✅ All pods terminated${NC}"
echo ""

# Step 4: Scale back up to 1 replica
echo "⬆️  Step 4: Scaling Vault deployment back to 1 replica..."
kubectl scale deployment vault -n vault --replicas=1
echo -e "${GREEN}✅ Deployment scaled up${NC}"
echo ""

# Step 5: Wait for new Vault pod to be created and ready
echo "⏳ Step 5: Waiting for new Vault pod to start..."
sleep 5
kubectl wait --for=condition=ready pod -l app=vault -n vault --timeout=300s
VAULT_POD=$(kubectl get pod -n vault -l app=vault -o jsonpath='{.items[0].metadata.name}')
echo -e "${GREEN}✅ Vault pod is ready: $VAULT_POD${NC}"
echo ""

# Step 4: Check if Vault is initialized
echo "🔍 Step 3: Checking Vault initialization status..."
sleep 5  # Give Vault a moment to start up

INIT_STATUS=$(kubectl exec -n vault "$VAULT_POD" -- vault status -format=json 2>/dev/null | jq -r '.initialized' || echo "false")

if [ "$INIT_STATUS" = "true" ]; then
    echo -e "${YELLOW}⚠️  Vault is already initialized${NC}"
    echo ""
    echo "You need to unseal Vault manually:"
    echo "1. Get your unseal key from vault-credentials.txt"
    echo "2. Run: kubectl exec -n vault $VAULT_POD -- vault operator unseal <UNSEAL_KEY>"
    echo ""
    echo "Then continue with the ESO setup."
else
    echo -e "${GREEN}✅ Vault is not initialized yet${NC}"
    echo ""
    echo "Vault is ready for initialization. Run the setup script:"
    echo "  cd k8s && bash setup-vault-eso.sh"
fi

echo ""
echo -e "${GREEN}✅ Vault pod restarted successfully${NC}"
