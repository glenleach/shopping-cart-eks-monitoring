#!/bin/bash

set -euo pipefail

# Set the namespace variable
NAMESPACE="monitoring"
CLUSTER_NAME="microservices"
REGION="us-west-2"

# Helper function to get pods with a timeout
get_pods_with_timeout() {
  local ns=$1
  local timeout=${2:-10}
  kubectl get pods -n "$ns" --request-timeout="${timeout}s" || echo "[ERROR] Unable to get pods in namespace $ns (timeout or connection issue)"
}

# Step 1: Create EKS cluster if it doesn't exist
if eksctl get cluster --region "$REGION" | grep -q "^$CLUSTER_NAME[[:space:]]"; then
  echo "EKS cluster '$CLUSTER_NAME' already exists in region '$REGION'. Skipping cluster creation."
else
  echo "Creating EKS cluster '$CLUSTER_NAME' in region '$REGION'..."
  eksctl create cluster --name "$CLUSTER_NAME" --region "$REGION" --nodes 2 --node-type t3.medium --managed
  echo "EKS cluster created."
fi

echo "Checking if namespace '$NAMESPACE' exists..."
if kubectl get namespace "$NAMESPACE" &>/dev/null; then
  echo "Namespace '$NAMESPACE' already exists. Skipping creation."
else
  echo "Creating namespace '$NAMESPACE'..."
  kubectl create namespace "$NAMESPACE"
fi

echo "Checking if microservices have already been deployed..."
if kubectl get deployment emailservice &>/dev/null; then
  echo "Deployment 'emailservice' already exists. Skipping config-microservices.yaml apply."
else
  echo "Applying microservices configuration..."
  yaml_file="config-microservices.yaml"
  kubectl apply -f "$yaml_file"
fi

echo "Updating Helm repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo update

echo "Checking if Helm release 'monitoring' exists in namespace '$NAMESPACE'..."
if helm status monitoring -n "$NAMESPACE" &>/dev/null; then
  echo "Helm release 'monitoring' already exists in namespace '$NAMESPACE'. Skipping installation."
  # Uncomment the next line to upgrade the release if desired:
  # helm upgrade monitoring prometheus-community/kube-prometheus-stack -n "$NAMESPACE"
else
  echo "Installing kube-prometheus-stack via Helm..."
  helm install monitoring prometheus-community/kube-prometheus-stack -n "$NAMESPACE"
fi

# Wait for Prometheus pod to appear (corrected label selector)
PROM_LABEL="app.kubernetes.io/name=prometheus,app.kubernetes.io/instance=monitoring-kube-prometheus-prometheus"
PROM_TIMEOUT=300
PROM_INTERVAL=5
PROM_TIME=0
PROM_POD_COUNT=0
echo "Waiting for Prometheus pod to appear..."
while [ $PROM_TIME -lt $PROM_TIMEOUT ]; do
  PROM_POD_COUNT=$(kubectl get pods -n "$NAMESPACE" -l $PROM_LABEL --no-headers --request-timeout=5s 2>/dev/null | wc -l)
  if [ "$PROM_POD_COUNT" -gt 0 ]; then
    break
  fi
  sleep $PROM_INTERVAL
  PROM_TIME=$((PROM_TIME+PROM_INTERVAL))
done
if [ "$PROM_POD_COUNT" -eq 0 ]; then
  echo "Prometheus pod did not appear in $PROM_TIMEOUT seconds. Current pods:"
  get_pods_with_timeout "$NAMESPACE" 10
  exit 1
fi

echo "Waiting for Prometheus pod to be ready..."
kubectl wait --for=condition=Ready pod -l $PROM_LABEL -n "$NAMESPACE" --timeout=300s || {
  echo "Prometheus pod did not become ready. Current pods:"
  get_pods_with_timeout "$NAMESPACE" 10
  exit 1
}

# Wait for Grafana pod to appear (corrected label selector)
GRAFANA_LABEL="app.kubernetes.io/name=grafana,app.kubernetes.io/instance=monitoring"
GRAFANA_TIMEOUT=300
GRAFANA_INTERVAL=5
GRAFANA_TIME=0
GRAFANA_POD_COUNT=0
echo "Waiting for Grafana pod to appear..."
while [ $GRAFANA_TIME -lt $GRAFANA_TIMEOUT ]; do
  GRAFANA_POD_COUNT=$(kubectl get pods -n "$NAMESPACE" -l $GRAFANA_LABEL --no-headers --request-timeout=5s 2>/dev/null | wc -l)
  if [ "$GRAFANA_POD_COUNT" -gt 0 ]; then
    break
  fi
  sleep $GRAFANA_INTERVAL
  GRAFANA_TIME=$((GRAFANA_TIME+GRAFANA_INTERVAL))
done
if [ "$GRAFANA_POD_COUNT" -eq 0 ]; then
  echo "Grafana pod did not appear in $GRAFANA_TIMEOUT seconds. Current pods:"
  get_pods_with_timeout "$NAMESPACE" 10
  exit 1
fi

echo "Waiting for Grafana pod to be ready..."
kubectl wait --for=condition=Ready pod -l $GRAFANA_LABEL -n "$NAMESPACE" --timeout=300s || {
  echo "Grafana pod did not become ready. Current pods:"
  get_pods_with_timeout "$NAMESPACE" 10
  exit 1
}

echo "Checking service status before port-forwarding..."
kubectl get svc -n "$NAMESPACE" --request-timeout=10s || echo "[ERROR] Unable to get services in namespace $NAMESPACE (timeout or connection issue)"

# Function to check if a service exists
does_service_exist() {
  local svc_name=$1
  kubectl get svc "$svc_name" -n "$NAMESPACE" --request-timeout=5s &>/dev/null
}

echo "Starting port-forward for Grafana on http://localhost:8080"
if does_service_exist monitoring-grafana; then
  kubectl port-forward -n "$NAMESPACE" svc/monitoring-grafana 8080:80 > grafana-portforward.log 2>&1 &
  sleep 2
else
  echo "Service monitoring-grafana not found in namespace $NAMESPACE!"
fi

echo "Starting port-forward for Prometheus on http://localhost:9090"
if does_service_exist monitoring-kube-prometheus-prometheus; then
  kubectl port-forward -n "$NAMESPACE" svc/monitoring-kube-prometheus-prometheus 9090:9090 > prometheus-portforward.log 2>&1 &
  sleep 2
else
  echo "Service monitoring-kube-prometheus-prometheus not found in namespace $NAMESPACE!"
fi

echo "Starting port-forward for Alertmanager on http://localhost:9093"
if does_service_exist monitoring-kube-prometheus-alertmanager; then
  kubectl port-forward -n "$NAMESPACE" svc/monitoring-kube-prometheus-alertmanager 9093:9093 > alertmanager-portforward.log 2>&1 &
  sleep 2
else
  echo "Service monitoring-kube-prometheus-alertmanager not found in namespace $NAMESPACE!"
fi

echo ""
echo "Access Grafana at: http://localhost:8080"
echo "Login with username: admin"
echo "Password: prom-operator"
echo ""
echo "Access Prometheus at: http://localhost:9090"
echo ""
echo "Access Alertmanager at: http://localhost:9093"
echo ""
echo "Check grafana-portforward.log, prometheus-portforward.log, and alertmanager-portforward.log for port-forwarding output or errors."
