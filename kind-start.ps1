# kind-start.ps

# Start a kind cluster
Write-Host "Starting kind cluster..."
# Check if the cluster already exists
$existingCluster = kind get clusters | Where-Object { $_ -eq "my-cluster" }

if ($existingCluster) {
    Write-Host "Cluster 'my-cluster' already exists. Deleting it..."
    kind delete cluster --name my-cluster

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to delete existing cluster 'my-cluster'." -ForegroundColor Red
        exit 1
    }

    Write-Host "Existing cluster 'my-cluster' deleted successfully."
}

# Create a new cluster
kind create cluster --name my-cluster

# Addd containers
kind load docker-image fastapi-service --name my-cluster
kind load docker-image hello-webapp --name my-cluster

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create kind cluster." -ForegroundColor Red
    exit 1
}

Write-Host "Kind cluster started successfully."


# Add argocd
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

## Get argocd password password
# Config
$namespace = "argocd"
$secretName = "argocd-initial-admin-secret"

Write-Host "Waiting for Argo CD pods to be ready..."

# Wait until all pods in the argocd namespace are Running
do {
    $pods = kubectl get pods -n $namespace
    $notReady = $pods -match '0/1|0/2|ContainerCreating|Pending|CrashLoopBackOff'
    if ($notReady) {
        Write-Host "  Still waiting on pods..."
        Start-Sleep -Seconds 3
    }
} while ($notReady)

Write-Host "All Argo CD pods are ready."

# Wait until the secret exists
Write-Host "Waiting for initial admin secret..."

do {
    $encoded = kubectl get secret $secretName -n $namespace -o jsonpath="{.data.password}" 2>$null
    if (-not $encoded) {
        Start-Sleep -Seconds 2
    }
} while (-not $encoded)

# Decode the password
$password = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))

Write-Host "Argo CD admin password:"
Write-Host "Username: admin"
Write-Host "Password: $password"

# create root app-store argo app
kubectl apply -f ./hello-cluster/app-store-apps.yaml

# Expose argodcd
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward svc/argocd-server -n argocd 8080:443"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward svc/hello-webapp -n hello-system 5000:5000"