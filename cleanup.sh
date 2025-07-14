#!/bin/bash

echo "Cleaning up EDA NetBox lab..."

# Stop any port-forwards
echo "Stopping port-forwards..."
pkill -f "kubectl port-forward.*netbox" 2>/dev/null || true

# Delete EDA resources
echo "Deleting EDA resources..."
kubectl delete -f manifests/0060_fabric.yaml 2>/dev/null || true
kubectl delete -f manifests/0050_asn_pool.yaml 2>/dev/null || true
kubectl delete -f manifests/0040_topolinks.yaml 2>/dev/null || true
kubectl delete -f manifests/0030_interfaces.yaml 2>/dev/null || true
kubectl delete -f manifests/0020_allocations.yaml 2>/dev/null || true
kubectl delete -f manifests/0010_netbox_instance.yaml 2>/dev/null || true

# Delete secrets
echo "Deleting secrets..."
kubectl delete secret netbox-api-token -n eda 2>/dev/null || true
kubectl delete secret netbox-webhook-signature -n eda 2>/dev/null || true

# Uninstall NetBox app from EDA
echo "Uninstalling NetBox app..."
cat << EOF | kubectl apply -f -
apiVersion: core.eda.nokia.com/v1
kind: Workflow
metadata:
  name: netbox-uninstall
  namespace: eda-system
spec:
  type: app-installer
  input:
    operation: uninstall
    apps:
      - app: netbox
        catalog: eda-catalog-builtin-apps
        vendor: nokia
EOF

# Wait for uninstall to complete
sleep 10

# Uninstall NetBox helm release
echo "Uninstalling NetBox helm release..."
helm uninstall netbox-server -n netbox 2>/dev/null || true

# Delete NetBox namespace
echo "Deleting NetBox namespace..."
kubectl delete namespace netbox --wait=false 2>/dev/null || true

# Clean up local files
echo "Cleaning up local files..."
rm -f .netbox_url .eda_api_address

echo "Cleanup completed!"