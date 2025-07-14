# EDA NetBox Integration Lab

This lab demonstrates the integration between Nokia EDA and NetBox for IPAM (IP Address Management) synchronization. It shows how EDA can dynamically create allocation pools based on NetBox's IPAM Prefixes and post allocated objects back to NetBox.

## Overview

The NetBox app in EDA enables:
- Dynamic creation of allocation pools based on NetBox Prefixes
- Synchronization of allocated resources back to NetBox
- Automated tracking of resource ownership

## Prerequisites

- Working EDA installation
- `kubectl` access to the EDA cluster
- `uv` tool (will be installed by init script)
- `helm` v3.x installed - https://helm.sh/docs/intro/install/

## Lab Components

### Topology
- 2 Spine switches (spine1, spine2)
- 2 Leaf switches (leaf1, leaf2)
- 2 Linux servers (server1, server2)
- All devices are Nokia SR Linux based

### NetBox Integration Features
- Webhook for real-time updates
- Event rules for IPAM synchronization
- Custom fields for EDA tracking
- Pre-configured tags and prefixes

## Quick Start

1. **Initialize the lab**:
   ```bash
   ./init.sh
   ```
   This will:
   - Install NetBox using Helm ( takes ~10 minutes )
   - Create Kubernetes secrets
   - Configure webhook endpoint
   - Set up initial prefixes and tags

2. **Configure NetBox** (optional - for manual setup):
   ```bash
   uv run scripts/configure_netbox.py
   ```

3. **Deploy Containerlab topology**:
   ```bash
   containerlab deploy -t eda-nb.clab.yaml
   ```

4. **Import topology to EDA**:
   ```bash
   clab-connector integrate \
   --topology-data clab-eda-nb/topology-data.json \
   --eda-url "https://$(cat .eda_api_address)" \
   --skip-edge-intfs
   ```

5. **Apply EDA resources**:
   ```bash
   # Install NetBox app
   kubectl apply -f manifests/0001_netbox_app_install.yaml
   
   # Wait for app to be ready
   
   # Apply remaining resources
   kubectl apply -f manifests/
   ```

## Accessing Services

### NetBox UI
- URL: Check `.netbox_url` file or run `kubectl get svc -n netbox`
- Username: `admin`
- Password: `netbox`

### EDA API
- Stored in `.eda_api_address` file

## Resource Types

### NetBox Instance
Defines connection to NetBox:
```yaml
apiVersion: netbox.eda.nokia.com/v1alpha1
kind: Instance
metadata:
  name: netbox
  namespace: eda
spec:
  url: http://netbox-server.netbox.svc.cluster.local
  apiToken: netbox-api-token
  signatureKey: netbox-webhook-signature
```

### Allocation Resources
Map NetBox prefixes to EDA allocation pools:

| Type | EDA Pool | Use Case |
|------|----------|----------|
| `ip-address` | IPAllocationPool | System IPs |
| `ip-in-subnet` | IPInSubnetAllocationPool | Management IPs |
| `subnet` | SubnetAllocationPool | ISL links |

## Example Workflow

1. **Create Prefix in NetBox**:
   - Navigate to IPAM → Prefixes
   - Add prefix (e.g., `192.168.100.0/24`)
   - Set Status to `Active` (for IP pools) or `Container` (for subnet pools)
   - Add appropriate tag (e.g., `eda-systemip-v4`)

2. **EDA Creates Allocation Pool**:
   - NetBox sends webhook to EDA
   - EDA creates matching allocation pool
   - Pool name matches Allocation resource name

3. **Use in Fabric**:
   ```yaml
   apiVersion: fabrics.eda.nokia.com/v1alpha1
   kind: Fabric
   metadata:
     name: netbox-ebgp-fabric
   spec:
     systemPoolIPV4: nb-systemip-v4
     interSwitchLinks:
       poolIPV4: nb-isl-v4
   ```

4. **View Allocations in NetBox**:
   - Allocated IPs appear under original prefix
   - Custom fields show EDA owner and allocation

## Pre-configured Resources

### Tags
- `eda-systemip-v4` - IPv4 System IPs
- `eda-systemip-v6` - IPv6 System IPs
- `eda-isl-v4` - IPv4 ISL subnets
- `eda-isl-v6` - IPv6 ISL subnets
- `eda-mgmt-v4` - Management IPs
- `EDAManaged` - Auto-assigned to EDA allocations

### Prefixes
- `192.168.10.0/24` - System IPs (Active)
- `10.0.0.0/16` - ISL subnets (Container)
- `2001:db8::/32` - IPv6 System IPs (Active)
- `2005::/64` - IPv6 ISL subnets (Container)
- `172.16.0.0/16` - Management IPs (Active)

## Troubleshooting

### Check NetBox connectivity:
```bash
kubectl get instance netbox -n eda -o yaml
```

### View allocation status:
```bash
kubectl get allocation -n eda
```

### Check webhook logs:
```bash
kubectl logs -n eda-system -l app=netbox
```

### Port forwarding (if LoadBalancer not available):
```bash
kubectl port-forward -n netbox service/netbox-server 8001:80 --address=0.0.0.0
```

## Cleanup

To remove all lab resources:
```bash
./cleanup.sh
sudo containerlab destroy -t eda-nb.clab.yaml
```

## Additional Resources

- [EDA NetBox App Detailed Guide](https://docs.eda.dev/25.4/apps/netbox/) - Comprehensive documentation on the NetBox app including configuration examples and troubleshooting
- [NetBox Documentation](https://docs.netbox.dev/)
- [Containerlab Documentation](https://containerlab.dev/)