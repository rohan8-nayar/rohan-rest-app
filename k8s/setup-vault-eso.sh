#!/bin/bash

# HashiCorp Vault + External Secrets Operator Setup Script
# This script initializes and configures Vault with database credentials for ESO

set -e

echo "🔐 HashiCorp Vault + ESO Setup Script"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq not found. Installing jq...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install jq
    else
        echo -e "${RED}Please install jq manually: https://stedolan.github.io/jq/download/${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo ""

# Step 1: Label nodes for infrastructure workloads
echo "📋 Step 1: Labeling nodes for infrastructure workloads..."
CONTROL_PLANE_NODE=$(kubectl get nodes --selector='node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}')
if [ -n "$CONTROL_PLANE_NODE" ]; then
    kubectl label nodes "$CONTROL_PLANE_NODE" type=infrastructure --overwrite
    echo -e "${GREEN}✅ Labeled $CONTROL_PLANE_NODE with type=infrastructure${NC}"
else
    echo -e "${YELLOW}⚠️  No control-plane node found. Please label a node manually:${NC}"
    echo "   kubectl label nodes <node-name> type=infrastructure"
fi
echo ""

# Step 2: Deploy Vault
echo "🚀 Step 2: Deploying HashiCorp Vault..."
kubectl apply -f vault.yml
echo -e "${GREEN}✅ Vault manifests applied${NC}"
echo ""

# Wait for Vault pod to be ready
echo "⏳ Waiting for Vault pod to be ready..."
kubectl wait --for=condition=ready pod -l app=vault -n vault --timeout=300s
echo -e "${GREEN}✅ Vault pod is ready${NC}"
echo ""

# Step 3: Initialize Vault
echo "🔑 Step 3: Initializing Vault..."
VAULT_POD=$(kubectl get pod -n vault -l app=vault -o jsonpath='{.items[0].metadata.name}')

# Check if Vault is already initialized
INIT_STATUS=$(kubectl exec -n vault "$VAULT_POD" -- vault status -format=json 2>/dev/null | jq -r '.initialized' || echo "false")

if [ "$INIT_STATUS" = "true" ]; then
    echo -e "${YELLOW}⚠️  Vault is already initialized${NC}"
    echo "Please provide the unseal key and root token manually."
    echo ""
else
    echo "Initializing Vault with 1 key share and 1 key threshold..."
    INIT_OUTPUT=$(kubectl exec -n vault "$VAULT_POD" -- vault operator init -key-shares=1 -key-threshold=1 -format=json)
    
    UNSEAL_KEY=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[0]')
    ROOT_TOKEN=$(echo "$INIT_OUTPUT" | jq -r '.root_token')
    
    # Save credentials to file (IMPORTANT: Keep this secure!)
    VAULT_CREDS_FILE="vault-credentials.txt"
    cat > "$VAULT_CREDS_FILE" << EOF
Vault Credentials - KEEP THIS SECURE!
=====================================
Unseal Key: $UNSEAL_KEY
Root Token: $ROOT_TOKEN

Generated: $(date)
EOF
    
    echo -e "${GREEN}✅ Vault initialized successfully${NC}"
    echo -e "${YELLOW}⚠️  IMPORTANT: Vault credentials saved to $VAULT_CREDS_FILE${NC}"
    echo -e "${YELLOW}⚠️  Keep this file secure and back it up!${NC}"
    echo ""
    
    # Step 4: Unseal Vault
    echo "🔓 Step 4: Unsealing Vault..."
    kubectl exec -n vault "$VAULT_POD" -- vault operator unseal "$UNSEAL_KEY"
    echo -e "${GREEN}✅ Vault unsealed${NC}"
    echo ""
fi

# If Vault was already initialized, prompt for unseal key and root token
if [ "$INIT_STATUS" = "true" ]; then
    read -p "Enter Vault unseal key: " UNSEAL_KEY
    read -p "Enter Vault root token: " ROOT_TOKEN
    
    echo "🔓 Unsealing Vault..."
    kubectl exec -n vault "$VAULT_POD" -- vault operator unseal "$UNSEAL_KEY"
    echo -e "${GREEN}✅ Vault unsealed${NC}"
    echo ""
fi

# Step 5: Configure Vault
echo "⚙️  Step 5: Configuring Vault..."

# Enable KV v2 secrets engine
kubectl exec -n vault "$VAULT_POD" -- vault login "$ROOT_TOKEN" > /dev/null
kubectl exec -n vault "$VAULT_POD" -- vault secrets enable -path=secret kv-v2 2>/dev/null || echo "KV v2 already enabled"

# Enable Kubernetes auth method
kubectl exec -n vault "$VAULT_POD" -- vault auth enable kubernetes 2>/dev/null || echo "Kubernetes auth already enabled"

# Configure Kubernetes auth
KUBERNETES_HOST="https://kubernetes.default.svc.cluster.local:443"
kubectl exec -n vault "$VAULT_POD" -- vault write auth/kubernetes/config \
    kubernetes_host="$KUBERNETES_HOST"

echo -e "${GREEN}✅ Vault configured${NC}"
echo ""

# Step 6: Store database credentials in Vault
echo "💾 Step 6: Storing database credentials in Vault..."
DB_USERNAME="postgres"
DB_PASSWORD="postgres123"  # Change this in production!

kubectl exec -n vault "$VAULT_POD" -- vault kv put secret/database/students-api \
    username="$DB_USERNAME" \
    password="$DB_PASSWORD"

echo -e "${GREEN}✅ Database credentials stored in Vault at secret/database/students-api${NC}"
echo ""

# Step 7: Create Vault policy for ESO
echo "📜 Step 7: Creating Vault policy for External Secrets Operator..."
kubectl exec -n vault "$VAULT_POD" -- vault policy write external-secrets - <<EOF
path "secret/data/database/students-api" {
  capabilities = ["read"]
}
EOF

echo -e "${GREEN}✅ Vault policy created${NC}"
echo ""

# Step 8: Create Vault role for Kubernetes auth
echo "👤 Step 8: Creating Vault role for ESO service account..."
kubectl exec -n vault "$VAULT_POD" -- vault write auth/kubernetes/role/external-secrets \
    bound_service_account_names=external-secrets-vault \
    bound_service_account_namespaces=students-api \
    policies=external-secrets \
    ttl=1h

echo -e "${GREEN}✅ Vault role created${NC}"
echo ""

# Step 9: Deploy External Secrets Operator
echo "🚀 Step 9: Deploying External Secrets Operator..."
kubectl apply -f eso.yml
echo -e "${GREEN}✅ ESO manifests applied${NC}"
echo ""

# Wait for ESO pod to be ready
echo "⏳ Waiting for ESO pod to be ready..."
kubectl wait --for=condition=ready pod -l app=external-secrets -n external-secrets --timeout=300s
echo -e "${GREEN}✅ ESO pod is ready${NC}"
echo ""

# Step 10: Deploy ExternalSecret resources
echo "🔗 Step 10: Deploying ExternalSecret resources..."
kubectl apply -f external-secret.yml
echo -e "${GREEN}✅ ExternalSecret resources applied${NC}"
echo ""

# Wait a moment for ESO to sync secrets
echo "⏳ Waiting for secrets to be synced..."
sleep 10

# Verify secret was created
if kubectl get secret db-credentials -n students-api &> /dev/null; then
    echo -e "${GREEN}✅ db-credentials secret successfully synced from Vault!${NC}"
else
    echo -e "${RED}❌ Failed to sync db-credentials secret. Check ESO logs:${NC}"
    echo "   kubectl logs -n external-secrets -l app=external-secrets"
fi
echo ""

# Step 11: Update application deployment
echo "🔄 Step 11: Removing static secret from application.yml..."
echo -e "${YELLOW}⚠️  You need to manually remove the static Secret definition from k8s/application.yml${NC}"
echo "   Remove lines 29-39 (the db-credentials Secret)"
echo ""

echo "==============================================="
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo "==============================================="
echo ""
echo "Next steps:"
echo "1. Remove the static db-credentials Secret from k8s/application.yml"
echo "2. Apply the updated application.yml: kubectl apply -f k8s/application.yml"
echo "3. Restart your application pods: kubectl rollout restart deployment rohan-rest-api -n students-api"
echo ""
echo "Useful commands:"
echo "- View Vault logs: kubectl logs -n vault -l app=vault"
echo "- View ESO logs: kubectl logs -n external-secrets -l app=external-secrets"
echo "- Check ExternalSecret status: kubectl get externalsecret -n students-api"
echo "- Verify synced secret: kubectl get secret db-credentials -n students-api -o yaml"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Keep vault-credentials.txt secure and backed up!${NC}"
