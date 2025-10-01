# Cloud Build → Terraform → Private GKE (with Snyk IaC gate)

This repository demonstrates how I automated:

1. Bootstrapping a **private GKE** cluster and supporting network using **Terraform**  
2. Running a **Snyk Infrastructure-as-Code** scan against my Terraform configuration  
3. Failing the CI pipeline if high-severity issues are found (policy gate)  
4. Storing **Cloud Build logs in a user-owned GCS bucket** (required when using a custom build service account)  
5. Injecting `SNYK_TOKEN` securely into the build from **Secret Manager**

The pipeline is triggered by **Cloud Build** when I push to the `main` branch of this GitHub repo.

---

## Architecture

- **CI/CD**  
  Cloud Build pulls from GitHub and runs the steps defined in `cloudbuild.yaml`. I use a **custom service account** and a **user-owned logs bucket** to meet Cloud Build requirements.

- **Provisioning**  
  Terraform (pinned to 1.6.5 in the CI container) provisions:
  - VPC, subnet, Cloud Router and **Cloud NAT**  
  - A private **GKE cluster** with two node pools: `general` and `spot`  
  - Service accounts and Workload Identity bindings  
  - Example resources like a persistent disk and firewall rules  

- **Security**  
  - **Snyk IaC** scans my Terraform code and fails the build if high-severity findings are detected.  
  - **Secret Manager** securely provides the `SNYK_TOKEN` to the Snyk step.  

---

## Prerequisites

- Project: `cb-pipeline-demo`  
- My account has Owner-level permissions to set up buckets, secrets, and IAM.  
- GCS bucket for Terraform remote state is already configured.  
- I have a **Snyk account** and token.  
- GitHub repo is connected to Cloud Build.

---

## One-time Setup

### Environment Variables

```bash
export PROJECT_ID="cb-pipeline-demo"
export PROJECT_NUMBER="$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')"
export REGION="us-central1"
export ZONE="us-central1-a"
export TF_STATE_BUCKET="${PROJECT_ID}-tf-state"
export CB_LOGS_BUCKET="${PROJECT_ID}-cloudbuild-logs"
export SNYK_SECRET_NAME="snyk-token"
```

### Enable Required APIs

```bash
gcloud services enable   cloudbuild.googleapis.com   container.googleapis.com   compute.googleapis.com   secretmanager.googleapis.com   artifactregistry.googleapis.com   iam.googleapis.com   serviceusage.googleapis.com   --project "${PROJECT_ID}"
```

### Create Buckets

```bash
# Remote Terraform state bucket
gcloud storage buckets create "gs://${TF_STATE_BUCKET}"   --project="${PROJECT_ID}" --location="${REGION}"
gcloud storage buckets update "gs://${TF_STATE_BUCKET}" --versioning

# Logs bucket for Cloud Build (Option A)
gcloud storage buckets create "gs://${CB_LOGS_BUCKET}"   --project="${PROJECT_ID}" --location="${REGION}"
```

### Store Snyk Token in Secret Manager

```bash
gcloud secrets create "${SNYK_SECRET_NAME}"   --replication-policy="automatic"   --project="${PROJECT_ID}"

echo -n "${SNYK_TOKEN}" | gcloud secrets versions add "${SNYK_SECRET_NAME}"   --data-file=- --project="${PROJECT_ID}"
```

### Grant IAM to Cloud Build Service Account

```bash
# Allow Cloud Build to read the Snyk secret
gcloud secrets add-iam-policy-binding "${SNYK_SECRET_NAME}"   --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"   --role="roles/secretmanager.secretAccessor"   --project="${PROJECT_ID}"

# Allow Cloud Build to write logs to the logs bucket
gcloud storage buckets add-iam-policy-binding "gs://${CB_LOGS_BUCKET}"   --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"   --role="roles/storage.objectAdmin"
```

### Connect GitHub and Create Trigger

I connected this GitHub repo to Cloud Build and created a trigger on the `main` branch pointing to `cloudbuild.yaml`.

---

## Pipeline Behavior

- Step 0: 💻 `terraform init`  
- Step 1: Force delete leftover clusters with 🛠️ `gcloud container clusters delete`  
- Step 2: 💻 `terraform destroy -auto-approve -lock=false` (clean slate)  
- Step 3: 💻 `terraform plan`  
- Step 4: 💻 `terraform apply -auto-approve`  
- Step 5: 🔍 `snyk iac test --severity-threshold=high`  

**Important:**  
- Initially, the build failed when Snyk found:
  - **Unrestricted SSH** (firewall allowed 0.0.0.0/0)  
  - **GKE client certificate authentication enabled**  

I remediated these:  
- Updated `6-Firewalls.tf` to restrict SSH to a limited CIDR.  
- Refactored `7-Kubernetes.tf` to explicitly disable client certificate authentication.  

After these fixes, the pipeline completed successfully.

---

## Running Locally

Terraform:

```bash
terraform init
terraform plan -var="project_id=${PROJECT_ID}" -var="region=${REGION}"
terraform apply -auto-approve
```

To run the pipeline manually:

```bash
gcloud builds submit --config=cloudbuild.yaml --project="${PROJECT_ID}"
```

---

## Troubleshooting

- **Logs bucket error**: Fixed by creating a user-owned bucket and referencing it with `logsBucket` in the YAML.  
- **Secret Manager PermissionDenied**: Fixed by granting `roles/secretmanager.secretAccessor` to the Cloud Build service account.  
- **Build fails on Snyk findings**: This is expected. I fixed the flagged misconfigs and re-ran successfully.  

---

## Cleanup

```bash
terraform destroy -auto-approve
```

---

## Costs

This project incurs costs for:  
- GKE control plane and nodes  
- Cloud NAT static IP  
- Persistent disks  
- Cloud Build usage  

---

## Repo Structure

- `cloudbuild.yaml` – Pipeline definition with Terraform + Snyk steps  
- `1-Network.tf` – VPC, subnets, router, NAT  
- `6-Firewalls.tf` – Firewall rules (refactored to restrict SSH)  
- `7-Kubernetes.tf` – Private GKE cluster and node pools (client certs disabled)  
- Other Terraform files for service accounts, IAM, disks  
