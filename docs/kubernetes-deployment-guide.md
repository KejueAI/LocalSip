# LocalSip Kubernetes Deployment Guide

This guide walks you through deploying LocalSip on any Kubernetes cluster using Terraform. It covers building images, configuring the cluster, and deploying all services.

**Supported clusters**: EKS (AWS), GKE (Google Cloud), AKS (Azure), k3s, kubeadm, or any conformant Kubernetes cluster (v1.25+).

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Clone the Repository](#2-clone-the-repository)
3. [Build Docker Images](#3-build-docker-images)
4. [Push Images to a Registry](#4-push-images-to-a-registry)
5. [Prepare the Kubernetes Cluster](#5-prepare-the-kubernetes-cluster)
6. [Configure Terraform Variables](#6-configure-terraform-variables)
7. [Deploy with Terraform](#7-deploy-with-terraform)
8. [Set Up DNS](#8-set-up-dns)
9. [Seed the Database](#9-seed-the-database)
10. [Verify the Deployment](#10-verify-the-deployment)
11. [Appendix: TLS with cert-manager](#appendix-a-tls-with-cert-manager)
12. [Appendix: Private Registry (imagePullSecrets)](#appendix-b-private-registry-imagepullsecrets)
13. [Appendix: Storage Classes by Platform](#appendix-c-storage-classes-by-platform)
14. [Troubleshooting](#troubleshooting)

---

## 1. Prerequisites

Install the following tools on the machine where you will run the deployment.

| Tool | Minimum Version | Install |
|------|----------------|---------|
| **Git** | 2.x | https://git-scm.com/downloads |
| **Docker** | 24.x | https://docs.docker.com/get-docker/ |
| **Terraform** | 1.3+ | https://developer.hashicorp.com/terraform/install |
| **kubectl** | 1.25+ | https://kubernetes.io/docs/tasks/tools/ |
| **make** | any | Pre-installed on macOS/Linux |

You also need:

- A **running Kubernetes cluster** with `kubectl` configured (`kubectl get nodes` succeeds)
- A **container registry** accessible from the cluster (e.g., Docker Hub, ECR, GCR, ACR, Harbor, or a local registry)
- A **public IP address** for the FreeSWITCH media node (SIP/RTP traffic)
- Two **DNS records** (A or CNAME) for the API and WebSocket domains
- A **SignalWire account** (free) for building the FreeSWITCH image — sign up at https://signalwire.com

### Get a SignalWire Token

1. Go to https://signalwire.com and create a free account
2. After signing in, go to your **Personal Access Tokens** page (top-right menu > API Tokens, or visit https://id.signalwire.com/personal_access_tokens)
3. Click **Create Token** and copy the token value
4. Save it as `SIGNALWIRE_TOKEN` — you will need it in Step 3

---

## 2. Clone the Repository

```bash
git clone --recurse-submodules https://github.com/your-org/LocalSip.git
cd LocalSip
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

Verify submodules are populated:

```bash
ls vendor/somleng/Gemfile
ls vendor/somleng-switch/components/app/Gemfile
```

Both files must exist. If either is missing, re-run `git submodule update --init --recursive`.

---

## 3. Build Docker Images

LocalSip builds all images from vendored source code with patches applied. No external Docker image pulls are needed (except base images like `ruby`, `golang`, etc.).

Build all four images:

```bash
make build SIGNALWIRE_TOKEN=your_token_here
```

This builds:
- `localsip/somleng:latest` — API server (Ruby on Rails)
- `localsip/switch:latest` — Call controller (Adhearsion/Ruby)
- `localsip/freeswitch:latest` — Media server (FreeSWITCH)
- `localsip/rating-engine:latest` — Call rating (CGRates)

If you do not have a SignalWire token, you can build everything except FreeSWITCH:

```bash
make build-no-fs
```

> **Build time**: Expect 10-20 minutes for a clean build depending on your machine and internet speed.

Verify images exist:

```bash
docker images | grep localsip
```

Expected output (4 images):

```
localsip/somleng          latest    ...
localsip/switch           latest    ...
localsip/freeswitch       latest    ...
localsip/rating-engine    latest    ...
```

---

## 4. Push Images to a Registry

Your Kubernetes cluster needs to pull these images from a registry it can access. Choose the registry type that matches your setup.

### Option A: Docker Hub

```bash
# Log in
docker login

# Tag and push
make tag-and-push REGISTRY=yourdockerhubuser
```

### Option B: AWS ECR

```bash
# Create repositories (one-time)
ACCOUNT_ID=123456789012
REGION=ap-southeast-1

for repo in somleng switch freeswitch rating-engine; do
  aws ecr create-repository --repository-name $repo --region $REGION 2>/dev/null || true
done

# Log in to ECR
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Tag and push
make tag-and-push REGISTRY=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
```

### Option C: Google Artifact Registry

```bash
REGION=us-central1
PROJECT=your-gcp-project

# Log in
gcloud auth configure-docker $REGION-docker.pkg.dev

# Tag and push
make tag-and-push REGISTRY=$REGION-docker.pkg.dev/$PROJECT/localsip
```

### Option D: Local/Private Registry

If your cluster can access a local registry (e.g., Harbor, or k3s local registry at `registry.local:5000`):

```bash
make tag-and-push REGISTRY=registry.local:5000
```

After pushing, note your full image prefix (e.g., `123456789012.dkr.ecr.ap-southeast-1.amazonaws.com`). You will need it in Step 6.

---

## 5. Prepare the Kubernetes Cluster

### 5.1 Verify Cluster Access

```bash
kubectl get nodes
```

You should see your nodes listed as `Ready`. If this fails, fix your `kubectl` configuration first.

### 5.2 Install an Ingress Controller

An ingress controller routes external HTTP/HTTPS traffic to your services. Skip this if your cluster already has one installed.

**nginx-ingress** (recommended):

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/cloud/deploy.yaml
```

Wait for the ingress controller pod to become ready:

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

Verify:

```bash
kubectl get pods -n ingress-nginx
```

You should see a pod named `ingress-nginx-controller-*` with status `Running`.

> **Note for bare-metal/on-prem clusters**: Use the bare-metal manifest instead:
> ```bash
> kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/baremetal/deploy.yaml
> ```
> This creates a NodePort service instead of a LoadBalancer. You will need to configure an external load balancer or use the node IP + NodePort for access.

### 5.3 Label a Node for FreeSWITCH

FreeSWITCH uses `hostNetwork: true` and requires a node with a **known public IP** for SIP/RTP traffic. Label one node as the media server:

```bash
kubectl label node <NODE_NAME> somleng/role=media
```

Replace `<NODE_NAME>` with your node name (from `kubectl get nodes`).

**Important**: This node's public IP will be used as `fs_external_sip_ip` and `fs_external_rtp_ip` in Step 6. Open these ports on the node's firewall:

| Port | Protocol | Purpose |
|------|----------|---------|
| 5060 | UDP | SIP signaling |
| 5080 | UDP | SIP external profile |
| 16384-32768 | UDP | RTP media |
| 8021 | TCP | FreeSWITCH ESL (internal) |
| 5222 | TCP | FreeSWITCH healthcheck (internal) |

### 5.4 Set Up ReadWriteMany (RWX) Storage

The `sip-gateways` volume is shared between the Switch and FreeSWITCH pods and requires `ReadWriteMany` access mode. Choose one option based on your platform:

**AWS EKS — Amazon EFS**:

```bash
# Install the EFS CSI driver
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo update
helm install aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
  --namespace kube-system

# Create an EFS file system in AWS Console or CLI:
# aws efs create-file-system --creation-token somleng-sip-gateways --region $REGION
# Note the FileSystemId (e.g., fs-0123456789abcdef0)

# Create a StorageClass — save as efs-sc.yaml:
cat <<'EOF' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-YOUR_EFS_ID
  directoryPerms: "700"
EOF
```

Use `sip_gateways_storage_class = "efs-sc"` in your Terraform variables.

**k3s / On-Prem — Longhorn**:

```bash
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.8.1/deploy/longhorn.yaml

# Wait for Longhorn to be ready (takes 1-2 minutes)
kubectl wait --namespace longhorn-system \
  --for=condition=ready pod \
  --selector=app=longhorn-manager \
  --timeout=300s
```

Use `sip_gateways_storage_class = "longhorn"` in your Terraform variables.

**GKE — Filestore**:

GKE Filestore CSI driver is enabled by default on GKE clusters created after v1.21. Use storage class `standard-rwx`.

**AKS — Azure Files**:

Azure Files supports RWX by default. Use storage class `azurefile`.

**Any cluster — NFS**:

If none of the above options are available, you can use an NFS server. Install the NFS Subdir External Provisioner:

```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=YOUR_NFS_SERVER_IP \
  --set nfs.path=/exported/path
```

Use `sip_gateways_storage_class = "nfs-client"` in your Terraform variables.

---

## 6. Configure Terraform Variables

### 6.1 Create your variables file

```bash
cd infrastructure/kubernetes
cp terraform.tfvars.example terraform.tfvars
```

### 6.2 Edit terraform.tfvars

Open `terraform.tfvars` in your editor and fill in each section:

```hcl
# --- Cluster Authentication ---
# If kubectl is already configured, the defaults work. Otherwise uncomment:
# kubeconfig_path    = "~/.kube/config"
# kubeconfig_context = "my-cluster-name"

# --- Container Images ---
# Replace with your registry prefix from Step 4
somleng_image       = "YOUR_REGISTRY/somleng:latest"
switch_image        = "YOUR_REGISTRY/switch:latest"
freeswitch_image    = "YOUR_REGISTRY/freeswitch:latest"
rating_engine_image = "YOUR_REGISTRY/rating-engine:latest"

# --- Infrastructure Services ---
# Set to true to deploy Postgres and Redis inside the cluster (default).
# Set to false if you are using managed services (RDS, ElastiCache, Cloud SQL, etc.)
deploy_postgres = true
deploy_redis    = true

# If using managed services, set these:
# deploy_postgres = false
# deploy_redis    = false
# database_host   = "your-rds-endpoint.amazonaws.com"
# redis_host      = "your-redis-endpoint.amazonaws.com"

# --- Domains ---
api_domain         = "api.yourdomain.com"
ws_domain          = "ws.yourdomain.com"
dashboard_url_host = "https://api.yourdomain.com"

# --- FreeSWITCH ---
# Public IP of the node labeled somleng/role=media
fs_external_sip_ip = "YOUR_NODE_PUBLIC_IP"
fs_external_rtp_ip = "YOUR_NODE_PUBLIC_IP"

# --- Secrets ---
# Generate strong random values for each. Example:
#   openssl rand -hex 32
postgres_password      = "CHANGE_ME"
secret_key_base        = "CHANGE_ME"
fs_esl_password        = "CHANGE_ME"
anycable_secret        = "CHANGE_ME"
rating_engine_password = "CHANGE_ME"

# --- Storage ---
# Set the storage class for the sip-gateways PVC (must support ReadWriteMany).
# See Step 5.4 for which value to use based on your platform.
sip_gateways_storage_class = ""

# --- Ingress ---
ingress_class_name = "nginx"
```

### 6.3 Generate Secrets

Run these commands to generate secure random values:

```bash
echo "postgres_password      = \"$(openssl rand -hex 16)\""
echo "secret_key_base        = \"$(openssl rand -hex 64)\""
echo "fs_esl_password        = \"$(openssl rand -hex 16)\""
echo "anycable_secret        = \"$(openssl rand -hex 32)\""
echo "rating_engine_password = \"$(openssl rand -hex 16)\""
```

Copy the output and paste it into your `terraform.tfvars`, replacing the `CHANGE_ME` values.

### 6.4 Complete Variable Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `kubeconfig_path` | No | `~/.kube/config` | Path to kubeconfig file |
| `kubeconfig_context` | No | current context | Kubeconfig context name |
| `namespace` | No | `somleng` | Kubernetes namespace |
| `somleng_image` | No | `localsip/somleng:latest` | Somleng API image |
| `switch_image` | No | `localsip/switch:latest` | Switch image |
| `freeswitch_image` | No | `localsip/freeswitch:latest` | FreeSWITCH image |
| `rating_engine_image` | No | `localsip/rating-engine:latest` | Rating engine image |
| `anycable_ws_image` | No | `anycable/anycable-go:latest-alpine` | AnyCable WS image |
| `postgres_image` | No | `postgres:alpine` | PostgreSQL image |
| `redis_image` | No | `redis:alpine` | Redis image |
| `image_pull_policy` | No | `Always` | Image pull policy |
| `image_pull_secret_name` | No | `""` | K8s secret for private registry auth |
| `deploy_postgres` | No | `true` | Deploy PostgreSQL in-cluster |
| `deploy_redis` | No | `true` | Deploy Redis in-cluster |
| `database_host` | No | auto | Database hostname (set when `deploy_postgres=false`) |
| `database_username` | No | `somleng` | Database username |
| `redis_host` | No | auto | Redis hostname (set when `deploy_redis=false`) |
| `redis_port` | No | `6379` | Redis port |
| `api_domain` | No | `api.yourdomain.com` | API ingress hostname |
| `ws_domain` | No | `ws.yourdomain.com` | WebSocket ingress hostname |
| `dashboard_url_host` | No | `https://dashboard.yourdomain.com` | Dashboard URL |
| `fs_external_sip_ip` | **Yes** | — | Public IP for SIP |
| `fs_external_rtp_ip` | **Yes** | — | Public IP for RTP |
| `freeswitch_node_selector` | No | `{"somleng/role"="media"}` | Node selector for FreeSWITCH |
| `postgres_password` | **Yes** | — | PostgreSQL password |
| `secret_key_base` | **Yes** | — | Rails secret key |
| `fs_esl_password` | **Yes** | — | FreeSWITCH ESL password |
| `anycable_secret` | **Yes** | — | AnyCable secret |
| `rating_engine_password` | **Yes** | — | Rating engine password |
| `postgres_storage_size` | No | `20Gi` | PostgreSQL PVC size |
| `postgres_storage_class` | No | cluster default | PostgreSQL storage class |
| `sip_gateways_storage_class` | No | cluster default | SIP gateways storage class (must be RWX) |
| `sip_gateways_storage_size` | No | `100Mi` | SIP gateways PVC size |
| `deploy_ingress` | No | `true` | Create Ingress resource |
| `ingress_class_name` | No | `null` | Ingress class (e.g., `nginx`) |
| `ingress_annotations` | No | `{}` | Ingress annotations |
| `ingress_tls_secret_name` | No | `""` | TLS secret name for Ingress |
| `somleng_api_replicas` | No | `2` | Number of API replicas |
| `rails_env` | No | `production` | Rails environment |
| `stub_rating_engine` | No | `false` | Stub the rating engine |

---

## 7. Deploy with Terraform

### 7.1 Initialize Terraform

```bash
cd infrastructure/kubernetes
terraform init
```

Expected output:

```
Terraform has been successfully initialized!
```

### 7.2 Preview the Deployment

```bash
terraform plan
```

Review the output. It should show resources to be created (namespace, config maps, secrets, deployments, services, ingress). The exact count will vary based on your settings (typically 18-22 resources).

### 7.3 Apply

```bash
terraform apply
```

Type `yes` when prompted.

Expected output:

```
Apply complete! Resources: XX added, 0 changed, 0 destroyed.

Outputs:

api_domain = "api.yourdomain.com"
api_service = "somleng-api"
database_host = "postgres.somleng.svc.cluster.local"
namespace = "somleng"
redis_url = "redis://redis.somleng.svc.cluster.local:6379/0"
ws_domain = "ws.yourdomain.com"
```

### 7.4 Wait for Pods to Start

```bash
kubectl get pods -n somleng -w
```

Wait until all pods show `Running` and `READY 1/1`. This typically takes 2-5 minutes as images are pulled and containers start up.

Expected pods:

```
NAME                               READY   STATUS    RESTARTS   AGE
anycable-rpc-xxxxx-xxxxx           1/1     Running   0          2m
anycable-ws-xxxxx-xxxxx            1/1     Running   0          2m
freeswitch-xxxxx-xxxxx             1/1     Running   0          2m
postgres-xxxxx-xxxxx               1/1     Running   0          2m    # if deploy_postgres=true
rating-engine-xxxxx-xxxxx          1/1     Running   0          2m
redis-xxxxx-xxxxx                  1/1     Running   0          2m    # if deploy_redis=true
somleng-api-xxxxx-xxxxx            1/1     Running   0          2m
somleng-api-xxxxx-yyyyy            1/1     Running   0          2m
somleng-scheduler-xxxxx-xxxxx      1/1     Running   0          2m
somleng-switch-xxxxx-xxxxx         1/1     Running   0          2m
```

If any pod is stuck in `ImagePullBackOff`, see [Troubleshooting](#troubleshooting).

Press `Ctrl+C` to stop watching once all pods are running.

---

## 8. Set Up DNS

### 8.1 Get the Ingress External IP

```bash
kubectl get ingress -n somleng
```

Note the `ADDRESS` column. This is the external IP or hostname of your ingress controller.

If the address is empty, get it from the ingress controller service:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

Note the `EXTERNAL-IP` value.

### 8.2 Create DNS Records

Create DNS A records (or CNAME records if the external IP is a hostname like an AWS ELB) pointing to the ingress external IP:

| Record Type | Name | Value |
|-------------|------|-------|
| A (or CNAME) | `api.yourdomain.com` | Ingress external IP |
| A (or CNAME) | `ws.yourdomain.com` | Ingress external IP |

Wait for DNS propagation (usually 1-5 minutes):

```bash
dig api.yourdomain.com +short
```

---

## 9. Seed the Database

After the first deployment, you need to create the database schema and seed initial data.

### 9.1 Run Database Migrations

```bash
kubectl exec -n somleng deploy/somleng-api -- \
  bundle exec rails db:create db:migrate db:seed
```

This creates the database tables and seeds the initial admin account.

### 9.2 Create an Admin Account

If the seed does not create an admin user, create one manually:

```bash
kubectl exec -it -n somleng deploy/somleng-api -- \
  bundle exec rails runner "
    Account.create!(
      name: 'Default',
      enabled: true
    )
  "
```

---

## 10. Verify the Deployment

### 10.1 Health Check

```bash
curl -s https://api.yourdomain.com/health_checks
```

Expected response: HTTP 200 with a JSON body.

If using HTTP (no TLS):

```bash
curl -s http://api.yourdomain.com/health_checks
```

### 10.2 WebSocket Health Check

```bash
curl -s https://ws.yourdomain.com/health
```

Expected response: HTTP 200.

### 10.3 Internal Service Checks

Verify all services are reachable from within the cluster:

```bash
# Check API
kubectl exec -n somleng deploy/somleng-api -- curl -s http://localhost:3000/health_checks

# Check Switch
kubectl exec -n somleng deploy/somleng-switch -- curl -s http://localhost:8080/health_checks

# Check Rating Engine
kubectl exec -n somleng deploy/rating-engine -- /usr/local/bin/docker-healthcheck.sh

# Check FreeSWITCH
kubectl exec -n somleng deploy/freeswitch -- fs_cli -x "status"
```

### 10.4 SIP Registration Test

To verify FreeSWITCH is accepting SIP traffic, you can use a SIP softphone (e.g., Ooh SIP, Ooh Ooh SIP, Ooh SIP Ooh) or the `sipsak` command-line tool:

```bash
sipsak -vv -s sip:test@YOUR_NODE_PUBLIC_IP:5060
```

---

## Appendix A: TLS with cert-manager

To enable automatic TLS certificates via Let's Encrypt:

### Install cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.yaml

# Wait for cert-manager pods
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=120s
```

### Create a ClusterIssuer

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

Replace `your-email@example.com` with a real email address for certificate expiry notifications.

### Update Terraform Variables

Add these to your `terraform.tfvars`:

```hcl
ingress_tls_secret_name = "somleng-tls"
ingress_annotations = {
  "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
}
```

Then apply:

```bash
terraform apply
```

cert-manager will automatically request and provision TLS certificates for both domains.

Verify the certificate:

```bash
kubectl get certificate -n somleng
```

The `READY` column should show `True` within 1-2 minutes.

---

## Appendix B: Private Registry (imagePullSecrets)

If your images are in a private registry that requires authentication:

### Create the Secret

```bash
kubectl create secret docker-registry regcred \
  --namespace somleng \
  --docker-server=YOUR_REGISTRY_URL \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PASSWORD \
  --docker-email=YOUR_EMAIL
```

**For AWS ECR**, generate a token:

```bash
# The namespace must exist first. Create it if needed:
kubectl create namespace somleng 2>/dev/null || true

TOKEN=$(aws ecr get-login-password --region $REGION)
kubectl create secret docker-registry regcred \
  --namespace somleng \
  --docker-server=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$TOKEN
```

> **Note**: ECR tokens expire every 12 hours. For production, consider using an ECR credential helper like [ecr-credential-provider](https://github.com/kubernetes/cloud-provider-aws/tree/master/cmd/ecr-credential-provider) or a CronJob that refreshes the secret.

### Update Terraform Variables

Add to your `terraform.tfvars`:

```hcl
image_pull_secret_name = "regcred"
```

Then apply:

```bash
terraform apply
```

> **Important**: The secret must be created in the `somleng` namespace **before** running `terraform apply`, OR you can run `terraform apply` first (pods will be in `ImagePullBackOff`), then create the secret, and the pods will automatically retry and succeed.

---

## Appendix C: Storage Classes by Platform

| Platform | PostgreSQL StorageClass | SIP Gateways StorageClass (RWX) |
|----------|------------------------|--------------------------------|
| **AWS EKS** | `gp3` (or `gp2`) | `efs-sc` (requires EFS CSI driver) |
| **GKE** | `standard` (or `premium-rwo`) | `standard-rwx` (Filestore) |
| **AKS** | `managed-premium` | `azurefile` |
| **k3s** | `local-path` (default) | `longhorn` (requires Longhorn) |
| **kubeadm** | cluster default | NFS provisioner or Longhorn |

Set these in `terraform.tfvars`:

```hcl
postgres_storage_class     = "gp3"       # example for EKS
sip_gateways_storage_class = "efs-sc"    # example for EKS
```

---

## Troubleshooting

### Pods stuck in `ImagePullBackOff`

```bash
kubectl describe pod -n somleng <POD_NAME>
```

Look at the **Events** section. Common causes:
- **Image not found**: Verify the image name and tag in `terraform.tfvars` match what you pushed in Step 4
- **Authentication required**: Set up `image_pull_secret_name` (see [Appendix B](#appendix-b-private-registry-imagepullsecrets))
- **Registry unreachable**: Verify cluster nodes can reach the registry (`docker pull` from a node)

### Pods stuck in `Pending`

```bash
kubectl describe pod -n somleng <POD_NAME>
```

Common causes:
- **No node matches selector**: For FreeSWITCH, verify a node is labeled `somleng/role=media` (`kubectl get nodes --show-labels`)
- **Insufficient resources**: Check if nodes have enough CPU/memory (`kubectl describe node <NODE>`)
- **PVC not bound**: Check PVC status (`kubectl get pvc -n somleng`). If the PVC is stuck in `Pending`, verify the storage class exists and the provisioner is running

### Pods in `CrashLoopBackOff`

```bash
kubectl logs -n somleng <POD_NAME> --previous
```

Common causes:
- **Database not ready**: The API and scheduler pods depend on PostgreSQL. Wait for the postgres pod to be `Running` first, then delete the crashing pod to restart it: `kubectl delete pod -n somleng <POD_NAME>`
- **Missing environment variables**: Check the pod's environment: `kubectl exec -n somleng <POD_NAME> -- env | sort`
- **Wrong database credentials**: Verify `postgres_password` in `terraform.tfvars` matches the password the database was initialized with

### FreeSWITCH not receiving SIP traffic

1. Verify the pod is running on the labeled node:
   ```bash
   kubectl get pod -n somleng -l app=freeswitch -o wide
   ```
2. Verify the node's public IP matches `fs_external_sip_ip`
3. Verify firewall rules allow UDP 5060 and UDP 16384-32768
4. Test SIP connectivity:
   ```bash
   # From outside the cluster:
   nc -zuv YOUR_NODE_PUBLIC_IP 5060
   ```

### Ingress returns 404 or 502

1. Verify the ingress controller is running:
   ```bash
   kubectl get pods -n ingress-nginx
   ```
2. Verify the ingress resource:
   ```bash
   kubectl describe ingress -n somleng somleng
   ```
3. Verify backend services are running:
   ```bash
   kubectl get endpoints -n somleng somleng-api anycable-ws
   ```
   Each should show IP addresses. If `<none>`, the corresponding pods are not ready.

### Database migration fails

If `db:create` fails with "database already exists", that is OK — the init-db SQL already created it. Run only:

```bash
kubectl exec -n somleng deploy/somleng-api -- bundle exec rails db:migrate db:seed
```

### How to re-deploy after image changes

After building and pushing new images:

```bash
# Restart all deployments to pull fresh images
kubectl rollout restart deployment -n somleng
```

Or to restart a specific deployment:

```bash
kubectl rollout restart deployment -n somleng somleng-api
```

### How to destroy the deployment

```bash
cd infrastructure/kubernetes
terraform destroy
```

Type `yes` when prompted. This removes all Kubernetes resources created by Terraform. Persistent volume data may be retained depending on the reclaim policy of your storage class.
