## Example: complete
This example is not intended to represent a production-ready or typical deployment. Its purpose is to demonstrate the full breadth of customization available in this module — every major input variable is set explicitly, and several optional features are enabled together that would not normally be combined (e.g., a Private Service Connect endpoint alongside an internet-facing load balancer, custom helm value overrides for every chart, and all optional helm charts enabled at once).

Use this example as a reference for what is possible, not as a starting point for a real deployment.

Notable patterns shown in this example:

- **Restricted API endpoint access**: The GKE API endpoint is publicly accessible, but `kubernetes_cluster_endpoint_access_list` restricts access to the provisioner host's IP (`local.provisioner_public_ip`).
- **Private Service Connect**: `create_ingress_psc = true` exposes the ingress load balancer as a Google Private Service Connect service so consumers in other projects (`ingress_psc_consumer_projects`) can reach it without traversing the public internet.
- **Custom helm values**: Each helm chart accepts a `*_values_overrides` input. This example loads those overrides from files in `templates/`. The ingress-nginx override is a `templatefile()`, allowing Terraform variables (such as `lb_source_ranges`) to be interpolated into the YAML.
- **GPU node pool**: A dedicated GPU node pool is defined alongside the CPU pool, tainted so only GPU workloads schedule onto it.

## Usage
```
terraform init
terraform apply
```
