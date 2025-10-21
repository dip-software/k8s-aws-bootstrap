# Node Scheduling Configuration Guide

This document outlines the node scheduling strategy implemented for this K3s cluster.

## Overview

The cluster uses a dual-node approach with K3s standard CriticalAddonsOnly configuration:
- **Control Plane Nodes**: Hidden from workload scheduling, run K3s control plane components
- **Critical Addon Worker Nodes**: Dedicated nodes with `CriticalAddonsOnly` taint for infrastructure components
- **Karpenter Managed Nodes**: Clean worker nodes for application workloads

## Critical Workloads (Critical Addon Nodes Only)

These workloads are configured with `CriticalAddonsOnly` tolerations to run ONLY on dedicated infrastructure nodes:

1. **Karpenter Controller**
   - Critical for cluster functionality
   - Must be available before Karpenter nodes exist
   - Configured in: `base/karpenter/karpenter-app.yaml`

2. **AWS Load Balancer Controller**
   - Critical for ingress and service load balancing
   - Configured in: `base/aws/aws-load-balancer-controller-app.yaml`

3. **cert-manager (all components)**
   - Critical for TLS certificate management
   - Includes controller, cainjector, and webhook
   - Configured in: `base/cert-manager/cert-manager-app.yaml`

4. **ArgoCD (all components)**
   - Critical for GitOps deployments and cluster management
   - Includes server, repo-server, and controller
   - Configured in: `base/argo-cd/argocd-app.yaml`

5. **AWS EBS CSI Driver Controller**
   - Critical for persistent volume provisioning
   - Configured in: `base/aws/aws-ebs-csi-driver-app.yaml`

6. **Kyverno**
   - Critical for policy enforcement and admission control
   - Configured in: `base/kyverno/kyverno-app.yaml`

7. **External DNS**
   - Critical for DNS record management
   - Configured in: `base/aws/external-dns-app.yaml`

8. **Amazon EKS Pod Identity Webhook**
   - Critical for IRSA (IAM Roles for Service Accounts) functionality
   - Required by many other critical workloads for AWS IAM integration
   - Configured in: `base/aws/amazon-eks-pod-identity-webhook-app.yaml`

9. **Prometheus Stack (all components)**
   - Critical for monitoring cluster health and critical workloads
   - Includes Prometheus, Grafana, Prometheus Operator, and kube-state-metrics
   - Configured in: `base/kube-prometheus-stack/kube-prometheus-stack-app.yaml`

10. **CoreDNS** (K3s built-in)
    - **IMPORTANT**: CoreDNS runs automatically on control plane nodes
    - Uses K3s standard CriticalAddonsOnly scheduling
    - No additional configuration needed

## Non-Critical Workloads (Regular Worker Nodes)

These workloads are configured to **avoid** critical addon nodes and run on Karpenter-managed workers:

- Ingress NGINX Controller
- Crossplane

## DaemonSet Workloads

These workloads run on ALL nodes and don't need special scheduling:
- AWS EBS CSI Driver Node (DaemonSet)
- Node Exporter (DaemonSet)
- Any other DaemonSets

## Configuration Validation

### For Critical Addon Worker Nodes

Ensure your critical addon worker nodes are tainted for critical addons only:

```bash
# Taint the nodes to allow only critical addons
kubectl taint nodes <node-name> CriticalAddonsOnly=true:NoExecute
```

All critical workloads are configured with the appropriate `CriticalAddonsOnly` tolerations to schedule on these dedicated nodes.

### For K3s Control Plane

K3s control plane nodes are automatically configured with:

```bash
# Automatic labels and taints (no manual configuration needed)
kubectl get nodes -l node-role.kubernetes.io/control-plane
```

## Troubleshooting

### Check Node Labels and Taints

```bash
kubectl get nodes --show-labels | grep -E "CriticalAddonsOnly"
kubectl describe nodes | grep -A5 -B5 "Taints"
```

### Check Pod Placement

```bash
# Critical workloads should be on critical addon nodes
kubectl get pods -A -o wide --field-selector spec.nodeName!=<critical-addon-node>

# Check specific workload placement
kubectl get pods -n karpenter -o wide
kubectl get pods -n kube-system -o wide | grep -E "(aws-load-balancer|coredns)"
kubectl get pods -n cert-manager -o wide
```

### Check Karpenter Node Provisioning

```bash
kubectl get nodes -l node-type=karpenter-managed
kubectl get nodeclaims
```

## Next Steps

1. Deploy the configuration using ArgoCD
2. Manually taint your critical addon worker nodes with `CriticalAddonsOnly=true:NoExecute`
3. Verify pod placement after deployment
4. Monitor Karpenter node provisioning
