# Node Scheduling Configuration Guide

This document outlines the node scheduling strategy implemented for this EKS cluster.

## Overview

The cluster uses a dual-node approach:
- **Static Worker Nodes**: Manually provisioned nodes labeled with `node-type: static-worker`
- **Karpenter Managed Nodes**: Dynamically provisioned nodes labeled with `node-type: karpenter-managed`

## Critical Workloads (Static Worker Nodes Only)

These workloads are configured with **required** nodeAffinity to run ONLY on static-worker nodes:

1. **Karpenter Controller**
   - Critical for cluster functionality
   - Must be available before Karpenter nodes exist
   - Configured in: `base/helm-charts/karpenter-argocd-app.yaml`

2. **AWS Load Balancer Controller**
   - Critical for ingress and service load balancing
   - Configured in: `overlays/nginx/aws-load-balancer-controller-argocd-app.yaml`

3. **cert-manager (all components)**
   - Critical for TLS certificate management
   - Includes controller, cainjector, and webhook
   - Configured in: `base/helm-charts/cert-manager-argocd-app.yaml`

4. **ArgoCD (all components)**
   - Critical for GitOps deployments and cluster management
   - Includes server, repo-server, and controller
   - Configured in: `base/helm-charts/argocd-argocd-app.yaml`

5. **AWS EBS CSI Driver Controller**
   - Critical for persistent volume provisioning
   - Configured in: `base/helm-charts/aws-ebs-csi-driver-argocd-app.yaml`

6. **Kyverno**
   - Critical for policy enforcement and admission control
   - Configured in: `base/helm-charts/kyverno-argocd-app.yaml`

7. **External DNS**
   - Critical for DNS record management
   - Configured in: `overlays/nginx/external-dns-argocd-app.yaml`

8. **Amazon EKS Pod Identity Webhook**
   - Critical for IRSA (IAM Roles for Service Accounts) functionality
   - Required by many other critical workloads for AWS IAM integration
   - Configured in: `base/helm-charts/amazon-eks-pod-identity-webhook-argocd-app.yaml`

9. **CoreDNS** (EKS Add-on)
   - **IMPORTANT**: CoreDNS is typically managed as an EKS add-on
   - You need to configure the EKS add-on to use nodeSelectors for static-worker nodes
   - This is not managed by ArgoCD apps in this repository
   - Configure via AWS EKS Console, CLI, or Terraform/Pulumi

## Non-Critical Workloads (Prefer Karpenter Nodes)

These workloads are configured with **preferred** nodeAffinity to run on Karpenter nodes, but can fall back to static nodes:

- Prometheus Stack (Prometheus, Grafana, Prometheus Operator, kube-state-metrics)
- Ingress NGINX Controller
- Crossplane

## DaemonSet Workloads

These workloads run on ALL nodes and don't need special scheduling:
- AWS EBS CSI Driver Node (DaemonSet)
- Node Exporter (DaemonSet)
- Any other DaemonSets

## Configuration Validation

### For Static Worker Nodes
Ensure your static worker nodes are labeled and tainted:
```bash
# Label the nodes
kubectl label nodes <node-name> node-type=static-worker

# Taint the nodes to prevent non-critical workloads from scheduling
kubectl taint nodes <node-name> node-role.kubernetes.io/static-worker=true:NoSchedule
```

All critical workloads are configured with the appropriate tolerations to schedule on tainted static-worker nodes.

### For CoreDNS (EKS Add-on)
Configure the CoreDNS EKS add-on to use nodeSelectors:
```json
{
  "nodeSelector": {
    "node-type": "static-worker"
  }
}
```

## Troubleshooting

### Check Node Labels
```bash
kubectl get nodes --show-labels | grep node-type
```

### Check Pod Placement
```bash
# Critical workloads should be on static-worker nodes
kubectl get pods -A -o wide --field-selector spec.nodeName!=<static-worker-node>

# Check specific workload placement
kubectl get pods -n karpenter -o wide
kubectl get pods -n kube-system -o wide | grep -E "(aws-load-balancer|coredns)"
kubectl get pods -n cert-manager -o wide
```

### Check Karpenter Node Labels
```bash
kubectl get nodes -l node-type=karpenter-managed
```

## Next Steps

1. Deploy the configuration using ArgoCD
2. Manually label your static worker nodes with `node-type=static-worker`
3. Configure CoreDNS EKS add-on with nodeSelector for static-worker nodes
4. Verify pod placement after deployment
5. Monitor Karpenter node provisioning