# 🏗️ Infrastructure Automation Platform (Capstone 2)

Fully automated Infrastructure-as-Code pipeline: Terraform provisions AWS
infrastructure, Ansible configures the servers, and Jenkins orchestrates the
whole flow with a manual approval gate before anything is applied.

## 🧱 What this builds

- **VPC** with public + private subnets, Internet Gateway, single NAT Gateway
- **Bastion host** (public subnet) as the only SSH entry point
- **Private app/agent nodes** reachable only through the bastion
- **Security groups** scoped to least privilege (no `0.0.0.0/0` SSH)
- **IAM role** with SSM + CloudWatch access, attached via instance profile

## ⚙️ Terraform structure

```
terraform/
├── backend-bootstrap/     # one-time: S3 state bucket + DynamoDB lock table
├── modules/
│   ├── network/            # VPC, subnets, IGW, NAT, route tables
│   ├── security/            # security groups
│   ├── iam/                 # instance role/profile
│   └── compute/             # bastion + private EC2 nodes
└── environments/
    └── dev/                 # root module wiring everything together,
                               # remote backend, workspace-aware naming
```

Remote state lives in S3 with DynamoDB state locking. Environments are
separated with Terraform **workspaces** (`dev`, `staging`, `prod` all share
the same config, isolated state).

## 🤖 Ansible structure

```
ansible/
├── inventory/aws_ec2.yml   # dynamic inventory - queries AWS by tag,
│                            # always matches what Terraform just built
├── roles/
│   ├── docker/
│   ├── k8s-prereqs/
│   ├── nginx/
│   ├── java/
│   ├── git/
│   ├── jenkins-agent/
│   └── app-deploy/
└── playbook.yml
```

Every role is idempotent — re-running `playbook.yml` against already
configured nodes produces zero changes.

## 🚀 Jenkins pipeline

1. Checkout
2. Terraform Init
3. Terraform Plan
4. **Manual Approval**
5. Terraform Apply
6. Generate Ansible inventory/config from Terraform outputs
7. Run Ansible playbooks
8. Verify: EC2 reachability, health checks over the bastion tunnel

## 🛠️ Setup

```bash
# one-time backend bootstrap
cd terraform/backend-bootstrap
terraform init && terraform apply -var="bucket_name=<your-unique-bucket>"

# then point terraform/environments/dev/backend.tf at that bucket/table

cd ../environments/dev
cp terraform.tfvars.example terraform.tfvars   # fill in your values
terraform init
terraform workspace new dev
terraform plan
terraform apply
```

## ✅ Validation performed

- EC2 reachability via SSH through bastion
- Security group rule correctness (no open SSH to the world)
- Application health check (`/health`) through NGINX
- Ansible idempotency verified (second run = 0 changed tasks)
- State locking verified (concurrent `apply` blocked as expected)

## 📐 Architecture

See `docs/architecture-diagram.png` (add your exported diagram here).

## 📄 License

MIT
