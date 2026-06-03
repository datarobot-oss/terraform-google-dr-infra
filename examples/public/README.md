## Example: public
Demonstrates the minimal set of input variables required to create all infrastructure needed to install the DataRobot application in a standard publicly accessible configuration.

In this example:

- A new VPC is created (the default).
- The GKE API endpoint is publicly accessible (the default).
- The ingress load balancer is internet-facing (the default), so the DataRobot application is reachable from the public internet.
- A public Cloud DNS zone is created (the default), so records created by external-dns are publicly resolvable.
- TLS is handled by cert-manager using Let's Encrypt. Provide a valid `email_address` for certificate expiry notifications.
- `storage_force_destroy` and `dns_zone_force_destroy` are disabled, and `kubernetes_cluster_deletion_protection` and `postgres_deletion_protection` are enabled, in production (`var.environment == "prod"`) to prevent accidental data loss.

## Required variables
| Variable | Description |
|---|---|
| `name` | Name prefix applied to all created resources |
| `environment` | One of `dev`, `staging`, or `prod` |
| `google_project_id` | Google project ID to deploy into |
| `region` | Google region to deploy into |
| `domain_name` | Domain name for the application (e.g. `datarobot.yourdomain.com`) |
| `email_address` | Email address for Let's Encrypt certificate notifications |

## Usage
1. Copy the example tfvars file and fill in your values:
```bash
cp terraform.tfvars.example terraform.tfvars
```
2. Edit `terraform.tfvars` with your project ID, region, domain name, and other required values.
3. Run Terraform:
```bash
terraform init
terraform apply
```
