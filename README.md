# 🏗️ Infrastructure Automation Platform (Capstone 2)

Fully automated Infrastructure-as-Code pipeline: Terraform provisions AWS
infrastructure, Ansible configures the servers, and Jenkins orchestrates the
whole flow with a manual approval gate before anything is applied. Built and
run end-to-end on AWS (`ap-south-1`), including a full teardown with zero
orphaned resources.

## 🧱 What this builds

- **VPC** (`10.0.0.0/16`) with a public + private subnet, Internet Gateway,
  single NAT Gateway
- **Bastion host** (`t3.small`, public subnet, Elastic IP) — the only SSH
  entry point, and where Jenkins itself runs
- **App node** (private subnet) — NGINX reverse proxy in front of a
  containerized demo app (`traefik/whoami`)
- **Jenkins agent node** (private subnet) — a real, separate build agent
  that connects back to the controller over WebSocket
- **Security groups** scoped to least privilege (SSH only from an admin
  IP, inter-node traffic scoped to the VPC CIDR, no `0.0.0.0/0` SSH)
- **IAM role** with SSM + CloudWatch access, attached via instance profile

## ⚙️ Terraform structure

terraform/
├── backend-bootstrap/ # one-time: S3 state bucket + DynamoDB lock table
├── modules/
│ ├── network/ # VPC, subnets, IGW, NAT, route tables
│ ├── security/ # security groups
│ ├── iam/ # instance role/profile
│ └── compute/ # bastion (+ Elastic IP) + private EC2 nodes
└── environments/
└── dev/ # root module wiring everything together,
# remote backend, workspace-aware naming


Remote state lives in S3 with DynamoDB state locking. Environments are
separated with Terraform **workspaces** — `dev` and `staging` share the same
config with fully isolated state (verified: planning `staging` showed 21
fresh resources to create, with zero effect on `dev`'s existing 21 resources).

## 🤖 Ansible structure

ansible/
├── inventory/aws_ec2.yml # dynamic inventory - queries AWS by tag,
│ # always matches what Terraform just built
├── group_vars/ # per-role variables (app image, jenkins secret, etc.)
├── roles/
│ ├── docker/
│ ├── k8s-prereqs/
│ ├── nginx/
│ ├── java/ # OpenJDK 21 - must match the Jenkins controller's
│ │ # Java version or the agent fails to connect
│ ├── git/
│ ├── jenkins-agent/ # modern WebSocket agent connection (not JNLP)
│ └── app-deploy/
└── playbook.yml


Every role is idempotent — re-running `playbook.yml` against already
configured nodes produces zero changes (verified: `changed=0` across all
three hosts on a clean second run).

## 🚀 Jenkins pipeline

1. Checkout
2. Terraform Init
3. Terraform Plan
4. **Manual Approval** — pauses for a human to review the plan before anything is applied
5. Terraform Apply
6. Ansible Galaxy collection install
7. Run Ansible playbooks (baseline config → NGINX + app deploy → Jenkins agent)
8. Verify: bastion reachability, app health check (`/health` through NGINX)

Result: `Finished: SUCCESS` end-to-end, Jenkins agent connected and online.

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

Jenkins itself runs directly on the bastion host (`t3.small`, 2GB RAM was
needed — a `t3.micro` ran out of memory under Jenkins + Terraform + Ansible
together). AWS credentials and the SSH key for reaching the private nodes
are placed under `/var/lib/jenkins/.aws` and `/var/lib/jenkins/.ssh`
respectively, since pipeline steps run as the `jenkins` system user.

## ✅ Validation performed

- EC2 reachability via SSH through the bastion
- Security group rule correctness (SSH restricted to a single admin IP)
- Application health check (`/health`) through NGINX to the app container
- Ansible idempotency verified (second run = 0 changed tasks, all hosts)
- Terraform workspace isolation verified (staging plan = 21 fresh resources, no effect on dev)
- State locking verified (DynamoDB lock table checked clean after every run, including interrupted ones)
- Full teardown verified (`terraform destroy` — 21 resources destroyed, 0 errors, no orphaned resources)

## 🩹 Real issues hit and fixed (worth knowing for the interview)

- **VPC hairpin NAT**: running Ansible *from* the bastion and proxying
  SSH through the bastion's own public IP fails — AWS doesn't allow a
  public IP to be reached from inside the VPC that owns it. Fix: when
  running from inside the VPC, connect to private IPs directly; only use
  the public-IP proxy trick from outside the VPC (e.g. from a laptop).
- **Java version mismatch**: the Jenkins controller (Java 21) generates
  an `agent.jar` that a Java 17 agent can't run
  (`UnsupportedClassVersionError`). Agent nodes must run the same major
  Java version as the controller.
- **Memory exhaustion on `t3.micro`**: Jenkins + Terraform + Ansible +
  apt operations together exceeded 1GB RAM with no swap, causing
  intermittent hangs. Fixed by adding a swapfile short-term, then
  properly upsizing to `t3.small` (2GB) with an Elastic IP attached
  first so the public address didn't change during the resize.
- **Ansible inventory `compose` vars outrank `group_vars`**: overriding
  a dynamic-inventory-set variable (like `ansible_host`) requires
  `host_vars`, not `group_vars` — group vars lose that precedence fight.

## 📐 Architecture

See `docs/architecture-diagram.png`.

## 📄 License

MIT