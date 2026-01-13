# Gateway API CRDs are installed via remote URLs in kustomize
# For Helm, we reference them as a note - they should be installed separately
# or via the Cilium chart which includes them when gatewayAPI.enabled=true

# The following CRDs are required for Gateway API v1.3.0:
# - gateway.networking.k8s.io_gatewayclasses.yaml
# - gateway.networking.k8s.io_gateways.yaml
# - gateway.networking.k8s.io_httproutes.yaml
# - gateway.networking.k8s.io_referencegrants.yaml
# - gateway.networking.k8s.io_grpcroutes.yaml

# These are typically installed by Cilium when gatewayAPI.enabled=true
# or can be installed manually from:
# https://github.com/kubernetes-sigs/gateway-api/releases
