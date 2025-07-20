#!/bin/bash

set -euo pipefail

NAMESPACE="monitoring"
CLUSTER_NAME="microservices"
REGION="us-west-2"

# Kill all kubectl port-forward processes
PORT_FORWARD_PIDS=$(pgrep -f "kubectl port-forward" || true)
if [ -n "$PORT_FORWARD_PIDS" ]; then
  echo "Killing kubectl port-forward processes: $PORT_FORWARD_PIDS"
  kill $PORT_FORWARD_PIDS || true
else
  echo "No kubectl port-forward processes found."
fi

# Uninstall Helm release (if namespace still exists)
if kubectl get namespace "$NAMESPACE" &>/dev/null; then
  if helm status monitoring -n "$NAMESPACE" &>/dev/null; then
    echo "Uninstalling Helm release 'monitoring' in namespace '$NAMESPACE'..."
    helm uninstall monitoring -n "$NAMESPACE"
  else
    echo "Helm release 'monitoring' not found in namespace '$NAMESPACE'."
  fi
else
  echo "Namespace '$NAMESPACE' does not exist, skipping Helm uninstall."
fi

# Delete monitoring namespace (removes all monitoring resources)
if kubectl get namespace "$NAMESPACE" &>/dev/null; then
  echo "Deleting namespace '$NAMESPACE'..."
  kubectl delete namespace "$NAMESPACE"
else
  echo "Namespace '$NAMESPACE' already deleted."
fi

# Delete microservices resources (if not in monitoring namespace)
if [ -f config-microservices.yaml ]; then
  echo "Deleting microservices resources from config-microservices.yaml..."
  kubectl delete -f config-microservices.yaml || true
else
  echo "config-microservices.yaml not found, skipping microservices deletion."
fi

# Delete EKS cluster
if eksctl get cluster --region "$REGION" | grep -q "^$CLUSTER_NAME[[:space:]]"; then
  echo "Deleting EKS cluster '$CLUSTER_NAME' in region '$REGION'..."
  eksctl delete cluster --name "$CLUSTER_NAME" --region "$REGION"
else
  echo "EKS cluster '$CLUSTER_NAME' does not exist in region '$REGION'."
fi

echo "All resources destroyed and port-forwards killed."
