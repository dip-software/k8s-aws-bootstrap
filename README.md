# bootstrap

This project provides a baseline configuration for dev clusters.

## Clean Cluster Destruction

To cleanly destroy a bootstrapped cluster, follow these steps in order to prevent resource leaks and ensure proper cleanup:

### 1. Stop Bootstrap ArgoCD App Auto-Sync

Disable automatic synchronization to prevent ArgoCD from recreating resources during cleanup:

```bash
kubectl patch application bootstrap -n argocd --type merge -p '{"spec":{"syncPolicy":{"automated":null}}}'
```

### 2. Switch Bootstrap App to Base Kustomize Root

Change the bootstrap app source to the minimal base configuration (removes overlays and complex resources):

```bash
kubectl patch application bootstrap -n argocd --type merge -p '{"spec":{"source":{"path":"."}}}'
```

Manually sync the bootstrap app to apply the base configuration:

```bash
kubectl -n argocd patch application bootstrap --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}'
```

### 3. Patch Karpenter NodePool to Zero CPU

Prevent Karpenter from provisioning new nodes during cleanup:

```bash
kubectl patch nodepool default -n karpenter --type merge -p '{"spec":{"limits":{"cpu":"0"}}}'
```

Verify the patch was applied:

```bash
kubectl get nodepool default -n karpenter -o jsonpath='{.spec.limits.cpu}'
```

### 4. Remove All NodeClaims

Delete all Karpenter-managed nodes gracefully:

```bash
# List all nodeclaims first
kubectl get nodeclaims -n karpenter

# Delete all nodeclaims
kubectl delete nodeclaims --all -n karpenter

# Wait for nodeclaims to be fully removed (may take a few minutes)
kubectl wait --for=delete nodeclaims --all -n karpenter --timeout=10m
```

### 5. Verify Cleanup

Confirm all Karpenter nodes are removed:

```bash
# Check for remaining nodeclaims
kubectl get nodeclaims -n karpenter

# Check for Karpenter-managed nodes
kubectl get nodes -l node-type=karpenter-managed
```

### 6. Proceed with Infrastructure Destruction

Once all Karpenter resources are cleaned up, you can safely proceed with destroying the cluster infrastructure using your IaC tool (Pulumi).

## Notes

- **Order matters**: Follow the steps sequentially to avoid resource leaks
- **Karpenter NodeClaims**: Must be deleted before destroying the cluster to prevent orphaned EC2 instances
- **Auto-sync disabled**: Prevents ArgoCD from fighting the cleanup process
- **Base configuration**: Switching to base removes complex resources like ingress controllers and external-dns that may have cloud resources attached