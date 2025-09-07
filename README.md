# Terraform KinD API Deployment

This project demonstrates how to deploy a simple FastAPI application on a local Kubernetes-in-Docker (KinD) cluster using Terraform, behind an NGINX Ingress controller.

## Project Structure

```
.
├── api/
│   ├── app.py              # FastAPI application
│   ├── Dockerfile          # Container definition
│   └── requirements.txt    # Python dependencies
├── terraform/
│   ├── main.tf            # Main Terraform configuration
│   ├── providers.tf       # Provider configurations
│   ├── variables.tf       # Variable definitions
│   ├── app/               # App module
│   │   ├── deployment.tf  # Kubernetes deployment
│   │   ├── service.tf     # Kubernetes service
│   │   ├── ingress.tf     # Kubernetes ingress
│   │   └── variables.tf   # App module variables
│   └── ingress/
│       └── nginx.tf       # NGINX Ingress controller
└── README.md              # This file
```

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) installed
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) installed

## API Endpoints

The FastAPI application provides the following endpoints:

- `GET /health` - Health check endpoint
- `GET /time` - Returns current epoch time
- `POST /echo` - Echoes back JSON payload with pod information

## Deployment Steps

### 1. Build the Docker Image

Build the API container image that will be deployed to KinD:

```bash
docker build -t local/api:dev api/
```

### 2. Create KinD Cluster

Create a KinD cluster named `tf-kind`:

```bash
kind create cluster --name tf-kind
```

Verify the cluster is running:

```bash
kind get clusters # should see tf-kind
```

Set kubectl context to the new cluster:

```bash
kubectl config use-context kind-tf-kind
```

### 3. Load Docker Image into KinD

Load the locally built image into the KinD cluster:

```bash
kind load docker-image local/api:dev --name tf-kind
```

### 4. Initialize and Apply Terraform

Navigate to the terraform directory:

```bash
cd terraform
```

Initialize Terraform:

```bash
terraform init
```

Review the planned changes:

```bash
terraform plan
```

Apply the configuration:

```bash
terraform apply
```

When prompted, type `yes` to confirm the deployment.

### 5. Set Up Port Forwarding

Since KinD runs in Docker, set up port forwarding to access the application:

```bash
kubectl port-forward -n ingress-nginx service/nginx-ingress-ingress-nginx-controller 8080:80
```

Keep this terminal open while testing the application.

### 6. Test the Application

Open a new terminal and test the API endpoints:

**Health Check:**
```bash
curl http://localhost:8080/health
```

**Time Endpoint:**
```bash
curl http://localhost:8080/time
```

**Echo Endpoint:**
```bash
curl -X POST http://localhost:8080/echo \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from Terraform and KinD!"}'
```

**Browser Access:**

You can also access the endpoints in your browser:
- http://localhost:8080/health
- http://localhost:8080/time


## Verification Commands

Check that all resources are running:

```bash
# Check all pods
kubectl get pods -A

# Check services
kubectl get svc -A

# Check ingress
kubectl get ingress

# Check NGINX ingress controller
kubectl get pods -n ingress-nginx
```

## Cleanup Steps

Follow these steps in order to properly terminate all deployments and clean up resources:

### 1. Stop Port Forwarding

In the terminal running port forwarding, press `Ctrl+C` to stop it:

```bash
# If port forwarding is running in foreground, press Ctrl+C
# If running in background, find and kill the process:
ps aux | grep "kubectl port-forward"
kill <process_id>
```

### 2. Verify Current Deployments

Before cleanup, check what's currently running:

```bash
# Check all resources in the cluster
kubectl get all -A

# Check specifically the API deployment
kubectl get pods,svc,ingress -o wide

# Check NGINX ingress controller
kubectl get pods -n ingress-nginx
```

### 3. Manual Deployment Cleanup (Alternative to Terraform)

If you want to manually delete specific deployments without using Terraform destroy:

```bash
# Delete the API resources
kubectl delete deployment api
kubectl delete service api-svc
kubectl delete ingress api-ing

# Delete the NGINX ingress controller (if installed via kubectl)
kubectl delete namespace ingress-nginx

# Or if using Helm directly:
helm uninstall nginx-ingress -n ingress-nginx
```

### 4. Destroy Terraform Resources (Recommended)

Navigate to terraform directory and destroy all resources:

```bash
cd terraform
terraform destroy
```

When prompted, type `yes` to confirm the destruction.

**Verify cleanup:**
```bash
# Check that resources are being terminated
kubectl get pods -A

# Check Terraform state
terraform show
```

### 5. Stop and Delete the KinD Cluster

**Option A: Delete the cluster (removes everything):**
```bash
kind delete cluster --name tf-kind
```

**Option B: Just stop the cluster containers (preserves cluster for later):**
```bash
# Stop the cluster container
docker stop tf-kind-control-plane

# Start it again later if needed
docker start tf-kind-control-plane
```

**Verify cluster deletion:**
```bash
# Check that cluster is gone
kind get clusters

# Verify Docker containers are removed
docker ps -a | grep tf-kind
```

### 6. Clean Up Docker Images (Optional)

Remove the locally built images:

```bash
# Remove your custom API image
docker rmi local/api:dev

# Remove KinD node images (optional - saves disk space)
docker rmi kindest/node:v1.29.2

# Clean up all unused Docker resources
docker system prune -f
```

### 7. Reset kubectl Context (Optional)

If you have other Kubernetes clusters, switch context:

```bash
# List available contexts
kubectl config get-contexts

# Switch to another context
kubectl config use-context <other-context>

# Or remove the KinD context entirely
kubectl config delete-context kind-tf-kind
kubectl config delete-cluster kind-tf-kind
```

## Quick Cleanup Script

For convenience, here's a one-liner to clean everything up:

```bash
# Stop port forwarding (if running), destroy Terraform, delete cluster
pkill -f "kubectl port-forward" ; cd terraform && terraform destroy -auto-approve ; cd .. && kind delete cluster --name tf-kind && docker rmi local/api:dev
```

**⚠️ Warning:** This will destroy everything without confirmation prompts!

## Troubleshooting

### Common Issues

1. **Docker image not found in KinD:**
   - Ensure you've loaded the image: `kind load docker-image local/api:dev --name tf-kind`

2. **Terraform provider errors:**
   - Make sure KinD cluster is running: `kind get clusters`
   - Verify kubectl context: `kubectl config current-context`

3. **Port forwarding connection refused:**
   - Check if NGINX ingress controller is running: `kubectl get pods -n ingress-nginx`
   - Wait for the pod to be in `Running` state

4. **API endpoints return 404:**
   - Verify ingress is created: `kubectl get ingress`
   - Check ingress controller logs: `kubectl logs -n ingress-nginx deployment/nginx-ingress-ingress-nginx-controller`

### Useful Debug Commands

```bash
# Check cluster info
kubectl cluster-info

# View pod logs
kubectl logs deployment/api

# Describe ingress
kubectl describe ingress api-ing

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

## Architecture

This deployment creates:

1. **KinD Cluster**: Local Kubernetes cluster running in Docker
2. **API Deployment**: 2 replicas of the FastAPI application
3. **Service**: ClusterIP service exposing the API internally
4. **NGINX Ingress Controller**: Deployed via Helm in `ingress-nginx` namespace
5. **Ingress Resource**: Routes external traffic to the API service

The traffic flow is:
```
Browser → localhost:8080 → Port Forward → NGINX Ingress Controller → API Service → API Pods
```

## Security Notes

- This setup is for local development/demonstration only
- The KinD cluster is not secured for production use
- No TLS/SSL certificates are configured
- All traffic is HTTP (not HTTPS)

## Next Steps

To enhance this deployment for production:

1. Add TLS certificates for HTTPS
2. Implement proper secret management
3. Add monitoring and logging
4. Configure resource limits and requests
5. Add network policies
6. Implement CI/CD pipeline
