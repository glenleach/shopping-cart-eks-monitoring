
# Prometheus Monitoring Projects

This repository serves as the **master controller** for multiple EKS-based monitoring projects using Prometheus and Grafana.

## 📁 Included Subprojects

### 1. [shopping-cart-eks-monitoring](https://github.com/glenleach/shopping-cart-eks-monitoring)

A Kubernetes microservices demo application deployed on Amazon EKS, featuring full observability with Prometheus, Grafana, and exporters.

### 2. [nodejs-eks-monitoring](https://github.com/glenleach/nodejs-eks-monitoring)

A standalone Node.js application deployed on EKS, integrated with Prometheus and Grafana for monitoring and alerting.

## 🔧 Features

- Automated Prometheus and Grafana deployment via Helm or manifests
- Metrics collection using Node Exporter and kube-state-metrics
- Configured dashboards and alerting rules
- EKS infrastructure setup scripts or Terraform configs (per subproject)

## 🚀 Getting Started

Clone this repository including submodules:

```bash
git clone --recurse-submodules https://github.com/glenleach/prometheus-monitoring.git
```

If you already cloned without --recurse-submodules, initialize submodules manually:

git submodule update --init --recursive

To update submodules to latest commits:

git submodule update --remote

---

📚 Additional Resources

Each subproject has its own README with setup instructions, architecture details, and deployment guides.
📬 Contact

For questions or help, reach out to Glen Leach.



---



