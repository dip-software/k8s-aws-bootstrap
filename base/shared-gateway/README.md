# Shared Gateway

This directory contains the shared Gateway API configuration.

## Components

- **Namespace**: `gateway` - Dedicated namespace for the shared gateway
- **Certificate**: Wildcard certificate for `*.${CLUSTER_FQDN}` issued by Let's Encrypt
- **Gateway**: Shared gateway with HTTP (port 80) and HTTPS (port 443) listeners

## Gateway Details

- **Name**: `shared-gateway`
- **Namespace**: `gateway`
- **GatewayClass**: `cilium`
- **Listeners**:
  - HTTP on port 80 (allows routes from all namespaces)
  - HTTPS on port 443 with TLS termination (allows routes from all namespaces)

## Usage

Applications in any namespace can reference this gateway using HTTPRoute resources.

### Example HTTPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app-route
  namespace: my-app-namespace
spec:
  parentRefs:
    - name: shared-gateway
      namespace: gateway
  hostnames:
    - "my-app.${CLUSTER_FQDN}"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: my-app-service
          port: 80
```

### Example with HTTP to HTTPS Redirect

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app-route-http
  namespace: my-app-namespace
spec:
  parentRefs:
    - name: shared-gateway
      namespace: gateway
      sectionName: http
  hostnames:
    - "my-app.${CLUSTER_FQDN}"
  rules:
    - filters:
        - type: RequestRedirect
          requestRedirect:
            scheme: https
            statusCode: 301
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app-route-https
  namespace: my-app-namespace
spec:
  parentRefs:
    - name: shared-gateway
      namespace: gateway
      sectionName: https
  hostnames:
    - "my-app.${CLUSTER_FQDN}"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: my-app-service
          port: 80
```

## Certificate Management

The wildcard certificate is automatically managed by cert-manager using Let's Encrypt with DNS01 validation via Route53.

- **Issuer**: `letsencrypt-prod` (ClusterIssuer)
- **Secret**: `${RESOURCE_PREFIX}-wildcard-tls` (in `gateway` namespace)
- **Domains**: 
  - `*.${CLUSTER_FQDN}`
  - `${CLUSTER_FQDN}`

## Verification

Check gateway status:

```bash
kubectl get gateway -n gateway
kubectl describe gateway shared-gateway -n gateway
```

Check certificate status:

```bash
kubectl get certificate -n gateway
kubectl describe certificate ${RESOURCE_PREFIX}-wildcard -n gateway
```

Check the gateway's external address:

```bash
kubectl get gateway shared-gateway -n gateway -o jsonpath='{.status.addresses[0].value}'
```
