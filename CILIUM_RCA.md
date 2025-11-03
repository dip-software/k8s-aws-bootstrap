# Cilium Gateway API Health Check Failure - Root Cause Analysis

**Date:** November 3, 2025  
**Cluster:** obs-eu-dev-cluster  
**Issue:** AWS NLB health checks failing for Cilium Gateway

## Executive Summary

The AWS Network Load Balancer health checks are failing because Cilium Gateway API is configured in "dedicated mode" (`external-envoy-proxy: true`) with `gateway-api-hostnetwork-enabled: false`. This configuration creates dummy service endpoints (`192.192.192.192:9999`) instead of routing traffic to actual Envoy proxies on the nodes.

## Current State

### Gateway Configuration
- **Gateway Name:** `shared-gateway`
- **Namespace:** `gateway`
- **Gateway Class:** `cilium`
- **Listeners:** HTTP (80), HTTPS (443)
- **Status:** Programmed and Accepted

### Service Configuration
```
NAME: cilium-gateway-shared-gateway
TYPE: LoadBalancer
CLUSTER-IP: 10.43.148.127
EXTERNAL-IP: k8s-gateway-ciliumga-e070c533ae-447b3c5d12d5c34b.elb.eu-west-2.amazonaws.com
PORTS: 80:30866/TCP,443:31163/TCP
```

### AWS Load Balancer Details
- **Type:** Network Load Balancer (NLB)
- **Scheme:** `internal` (despite `internet-facing` annotation)
- **Target Groups:** 
  - Port 30866 (HTTP) - All targets unhealthy
  - Port 31163 (HTTPS) - All targets unhealthy
- **Health Check:** TCP on traffic-port
- **Target Instances:** 5 nodes (all failing health checks)

### Service Endpoints
```
ENDPOINTS: 192.192.192.192:9999
```

**This is the problem:** The dummy IP indicates no actual pods are serving the Gateway traffic.

## Root Cause Analysis

### 1. Configuration Mismatch

**Cilium Configuration:**
```yaml
enable-gateway-api: "true"
external-envoy-proxy: "true"
gateway-api-hostnetwork-enabled: "false"
```

This combination means:
- Gateway API is enabled
- Cilium expects external/dedicated Envoy proxy pods
- Host network mode is disabled
- **Result:** No mechanism to route NodePort traffic to Envoy proxies

### 2. Missing Gateway Pods

```bash
$ kubectl get pods -n gateway
No resources found in gateway namespace.
```

In dedicated mode, Cilium creates the Service but expects separate Envoy proxy pods to be deployed. These pods are **not created automatically** by Cilium.

### 3. Cilium Envoy DaemonSet Not Configured for Gateway

The `cilium-envoy` DaemonSet exists in `kube-system` namespace:
- Runs in `hostNetwork: true` mode
- Has 5 healthy pods (one per node)
- **But:** Not configured to handle Gateway traffic because `gateway-api-hostnetwork-enabled: false`

### 4. LoadBalancer Scheme Ignored

Gateway annotation:
```yaml
service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
```

Actual LB scheme: `internal`

**Reason:** Cilium doesn't propagate Gateway annotations to the Service it creates. The Service needs annotations directly or via Cilium's Helm configuration.

### 5. Security Group Configuration

Security groups are correctly configured:
- Worker nodes allow traffic from LB security group on ports 30866-31163
- LB security group allows inbound traffic on ports 80 and 443
- **Not the issue:** Network connectivity is properly configured

## How Cilium Gateway API Works

### Dedicated Mode (Current - Not Working)
```
Internet → NLB → NodePort (30866/31163) → ??? (No pods listening) → ✗
```

- `external-envoy-proxy: true`
- Creates Service with dummy endpoints
- Expects user to deploy Envoy proxy pods manually
- No automatic pod creation

### Host Network Mode (Recommended)
```
Internet → NLB → NodePort (30866/31163) → cilium-envoy (hostNetwork) → Backend Services → ✓
```

- `gateway-api-hostnetwork-enabled: true`
- Uses existing `cilium-envoy` DaemonSet
- Envoy listens on NodePorts in host network namespace
- Health checks pass immediately

## Evidence

### 1. Dummy Endpoint
```bash
$ kubectl get endpoints -n gateway
NAME                            ENDPOINTS              AGE
cilium-gateway-shared-gateway   192.192.192.192:9999   7m52s
```

### 2. No Gateway Pods
```bash
$ kubectl get deployment,daemonset -n gateway
No resources found in gateway namespace.
```

### 3. Cilium Config Drift Warnings
```
level=warn msg="Mismatch found" key=enable-gateway-api actual=false expectedValue=true
level=warn msg="No local entry found" key=gateway-api-hostnetwork-enabled expectedValue=false
```

### 4. AWS Target Health
```json
{
  "TargetHealth": {
    "State": "unhealthy",
    "Reason": "Target.FailedHealthChecks",
    "Description": "Health checks failed"
  }
}
```

All 5 target instances are unhealthy on both ports (30866, 31163).

### 5. Cilium Service Mapping
```bash
$ kubectl exec -n kube-system cilium-jlhbt -- cilium-dbg service list | grep -E '30866|31163'
118   0.0.0.0:30866/TCP        NodePort
120   0.0.0.0:31163/TCP        NodePort
```

NodePorts exist in Cilium's service table but have no backend endpoints.

## Recommendations

### Option 1: Enable Host Network Mode ⭐ (Recommended)

**Change Required:**
Update `/Users/andy/DEV/Philips/dip-software/k8s-aws-bootstrap/base/cilium/cilium-app.yaml`:

```yaml
gatewayAPI:
  enabled: true
  hostNetwork:
    enabled: true
```

**Pros:**
- ✅ Simple one-line configuration change
- ✅ Uses existing `cilium-envoy` DaemonSet
- ✅ Health checks will pass immediately
- ✅ No additional pods or resources needed
- ✅ Well-tested and documented approach

**Cons:**
- ⚠️ Envoy runs in host network namespace (security consideration)
- ⚠️ All nodes will have Envoy listening on Gateway ports

**Impact:**
- Cilium will reconfigure the Service endpoints to point to actual node IPs
- `cilium-envoy` pods will start listening on NodePorts
- AWS health checks will pass within 30 seconds

### Option 2: Deploy Dedicated Envoy Pods

**Change Required:**
Keep current config but manually deploy Envoy proxy pods that:
- Listen on NodePorts 30866 and 31163
- Connect to Cilium's Envoy socket at `/var/run/cilium/envoy/sockets`
- Have proper labels matching the service selector

**Pros:**
- ✅ More isolated (not in host network)
- ✅ Can control which nodes run Gateway proxies
- ✅ Better security boundary

**Cons:**
- ❌ Complex manual configuration required
- ❌ Need to manage Envoy deployment lifecycle
- ❌ More moving parts to maintain
- ❌ Not officially documented by Cilium
- ❌ Requires custom Envoy configuration

**Not Recommended:** This approach is complex and not well-supported.

### Option 3: Use Dedicated Gateway Nodes

**Change Required:**
Enable host network mode with node selector:

```yaml
gatewayAPI:
  enabled: true
  hostNetwork:
    enabled: true
    nodeSelector:
      node-role: gateway
```

**Pros:**
- ✅ Limits Gateway traffic to specific nodes
- ✅ Better resource isolation
- ✅ Can scale Gateway capacity independently

**Cons:**
- ⚠️ Requires labeling nodes
- ⚠️ Need to ensure Gateway nodes exist
- ⚠️ More complex infrastructure management

## Additional Issues to Address

### 1. LoadBalancer Scheme (Internet-facing)

**Problem:** Gateway annotation is ignored, LB created as `internal` instead of `internet-facing`.

**Solution:** Add service annotations to Cilium Helm values:

```yaml
gatewayAPI:
  enabled: true
  hostNetwork:
    enabled: true
  serviceAnnotations:
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
```

### 2. ExternalTrafficPolicy

**Current:** `externalTrafficPolicy: Cluster`

**Recommendation:** Change to `Local` for:
- Better performance (no extra hop)
- Source IP preservation
- More accurate health checks

```yaml
gatewayAPI:
  enabled: true
  hostNetwork:
    enabled: true
  externalTrafficPolicy: Local
```

### 3. Gateway Annotations Not Propagated

**Issue:** Annotations on Gateway object are not propagated to the Service.

**Current Workaround:** Use Cilium's `serviceAnnotations` configuration.

**Long-term:** This is a known limitation of Cilium's Gateway API implementation.

## Implementation Plan

### Phase 1: Enable Host Network Mode (Immediate)

1. **Update Cilium configuration** in `base/cilium/cilium-app.yaml`:
   ```yaml
   gatewayAPI:
     enabled: true
     hostNetwork:
       enabled: true
     serviceAnnotations:
       service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
   ```

2. **Commit and sync** via ArgoCD (sync-wave: 0)

3. **Wait for Cilium restart** (may take 2-3 minutes)

4. **Verify service endpoints** are updated:
   ```bash
   kubectl get endpoints -n gateway cilium-gateway-shared-gateway
   ```
   Should show actual node IPs instead of `192.192.192.192:9999`

5. **Check AWS target health**:
   ```bash
   aws elbv2 describe-target-health --region eu-west-2 \
     --target-group-arn <arn>
   ```
   Should show `healthy` within 30 seconds

### Phase 2: Verify Traffic Flow

1. **Test HTTP endpoint**:
   ```bash
   curl -v http://<lb-dns-name>
   ```

2. **Test HTTPS endpoint**:
   ```bash
   curl -v https://<lb-dns-name>
   ```

3. **Check HTTPRoute**:
   ```bash
   kubectl get httproute -n starlift-observability go-hello-world -o yaml
   ```

4. **Verify certificate**:
   ```bash
   kubectl get certificate -n gateway obs-eu-dev-wildcard
   ```

### Phase 3: Optimize Configuration (Optional)

1. **Enable Local traffic policy** for better performance
2. **Add node selectors** if Gateway should run on specific nodes
3. **Configure resource limits** for cilium-envoy if needed
4. **Set up monitoring** for Gateway metrics

## Testing Checklist

- [ ] Cilium pods restart successfully
- [ ] Service endpoints updated to node IPs
- [ ] AWS target health checks pass
- [ ] HTTP traffic flows through Gateway
- [ ] HTTPS traffic flows through Gateway
- [ ] TLS certificate is valid
- [ ] HTTPRoute is properly attached
- [ ] Backend service receives traffic
- [ ] LoadBalancer is internet-facing (if required)
- [ ] Logs show no errors

## References

- [Cilium Gateway API Documentation](https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/)
- [Cilium Helm Values Reference](https://docs.cilium.io/en/stable/helm-reference/)
- [Gateway API Specification](https://gateway-api.sigs.k8s.io/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

## Conclusion

The health check failure is caused by Cilium's Gateway API being configured in dedicated mode without the required Envoy proxy pods. The solution is to enable host network mode (`gateway-api-hostnetwork-enabled: true`), which will use the existing `cilium-envoy` DaemonSet to handle Gateway traffic. This is a simple configuration change that will immediately resolve the health check failures.

The LoadBalancer scheme issue (internal vs internet-facing) is a secondary problem that can be resolved by adding service annotations to Cilium's Helm configuration.
