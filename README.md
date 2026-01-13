# bootstrap

This project provides a baseline configuration for Kubernetes clusters.

## Clean Cluster Destruction

To cleanly destroy a bootstrapped cluster, follow these steps to prevent resource leaks and ensure proper cleanup. The cleanup process is now integrated into the Helm chart.

### Automated Cleanup via Helm

1. Toggling the shutdown mode in your values:

```yaml
features:
  shutdown:
    enabled: true
```

2. When applied, this configuration triggers the following actions:
   - Disables auto-sync for the bootstrap application.
   - Sets Karpenter NodePool CPU limits to "0" to prevent new node provisioning.
   - Deploys a `cluster-cleanup` Job that:
     - Restarts Karpenter.
     - Deletes all NodeClaims.
     - Verifies cleanup of Karpenter-managed resources.
   - Removes shared Gateway resources (if enabled).

3. Monitor the cleanup job:

```bash
kubectl logs -n argocd job/cluster-cleanup -f
```

4. Once the job completes successfully, proceed with infrastructure destruction using your IaC tool (e.g., Pulumi).

## Notes

- **Order matters**: Follow the steps sequentially to avoid resource leaks
- **Karpenter NodeClaims**: Must be deleted before destroying the cluster to prevent orphaned EC2 instances
- **Shutdown Mode**: Enabling shutdown mode ensures the cluster is in a safe state for destruction by preventing new resource creation and actively cleaning up dynamic resources.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
