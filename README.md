### Deploy MS in EKS

[](https://github.com/glenleach/nodejs-eks-monitoring/tree/master#deploy-ms-in-eks)

```
eksctl create cluster
kubectl create namespace online-shop
kubectly apply -f ~/Demo-projects/Bootcamp/monitoring/config-microservices.yaml -n online-shop
```

# OPTIONAL for Linode

[](https://github.com/glenleach/nodejs-eks-monitoring/tree/master#optional-for-linode)

```
chmod 400 ~/Downloads/online-shop-kubeconfig.yaml
export KUBECONFIG=~/Downloads/online-shop-kubeconfig.yaml
```

### Deploy Prometheus Operator Stack

[](https://github.com/glenleach/nodejs-eks-monitoring/tree/master#deploy-prometheus-operator-stack)

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring
helm ls
```

[Link to the chart: [https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)]

### Check Prometheus Stack Pods

[](https://github.com/glenleach/nodejs-eks-monitoring/tree/master#check-prometheus-stack-pods)

```
kubectl get all -n monitoring
```

### Access Prometheus UI

[](https://github.com/glenleach/nodejs-eks-monitoring/tree/master#access-prometheus-ui)

```
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring &
```

### Access Grafana

[](https://github.com/glenleach/nodejs-eks-monitoring/tree/master#access-grafana)

```
kubectl port-forward svc/monitoring-grafana 8080:80 -n monitoring &
user: admin
pwd: prom-operator
```

### Trigger CPU spike with many requests

[](https://github.com/glenleach/nodejs-eks-monitoring/tree/master#trigger-cpu-spike-with-many-requests)

##### Deploy a busybox pod so we can curl our application

[](https://github.com/glenleach/nodejs-eks-monitoring/tree/master#deploy-a-busybox-pod-so-we-can-curl-our-application)

```
kubectl run curl-test --image=radial/busyboxplus:curl -i --tty --rm
```

##### create a script which curls the application endpoint. The endpoint is the external loadbalancer service endpoint

[](https://github.com/glenleach/nodejs-eks-monitoring/tree/master#create-a-script-which-curls-the-application-endpoint-the-endpoint-is-the-external-loadbalancer-service-endpoint)

```
for i in $(seq 1 10000)
do
  curl ae4aee0715edc46b988c6ce67121bf57-1459479566.eu-west-3.elb.amazonaws.com > test.txt
done
```

### Access Alert manager UI

[](https://github.com/glenleach/nodejs-eks-monitoring/tree/master#access-alert-manager-ui)

```
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093 &
```

#### Create cpu stress

[](https://github.com/glenleach/nodejs-eks-monitoring/tree/master#create-cpu-stress)

```
kubectl delete pod cpu-test; kubectl run cpu-test --image=containerstack/cpustress -- --cpu 4 --timeout 60s --metrics-brief
```

### Deploy Redis Exporter

[](https://github.com/glenleach/nodejs-eks-monitoring/tree/master#deploy-redis-exporter)

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://charts.helm.sh/stable
helm repo update

helm install redis-exporter prometheus-community/prometheus-redis-exporter -f redis-values.yaml
```
