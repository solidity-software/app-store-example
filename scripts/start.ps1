# start.ps

# Start a kind cluster
Write-Host "Starting kind cluster..."
# Check if the cluster already exists
$existingCluster = kind get clusters | Where-Object { $_ -eq "hello-cluster" }

if ($existingCluster) {
    Write-Host "Cluster 'hello-cluster' already exists. Deleting it..."
    kind delete cluster --name hello-cluster

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to delete existing cluster 'hello-cluster'." -ForegroundColor Red
        exit 1
    }

    Write-Host "Existing cluster 'hello-cluster' deleted successfully."
}

# Create a new cluster
kind create cluster --name hello-cluster

# build images
Write-Host "Building hello-service container"
docker build -t fastapi-service ../repos/tenant-source-repo/hello-service
Write-Host "Building hello-webapp container"
docker build -t hello-webapp ../repos/tenant-source-repo/hello-webapp

# Addd containers
Write-Host "Adding containers to kind"
kind load docker-image fastapi-service --name hello-cluster
kind load docker-image hello-webapp --name hello-cluster

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
        Write-Host "  Still waiting on argocd pods..."
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

# Expose ports
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward svc/argocd-server -n argocd 8080:443" -NoNewWindow
Write-Host "ArgoCD is not accessable at https://localhost:8080"

# create root app-store argo app
Write-Host "Creating root app-store app"
kubectl apply -f ../repos/hello-cluster-repo/bootstrap/cluster-bootstrap-app.yaml

while (-not (kubectl get pod -n hello-system -l app=hello-webapp -o name)) {
    Write-Host "Waiting for webapp(system app) pod to be created..."
    Start-Sleep -Seconds 2
}
Write-Host "webapp pod created!, Exposing on port 5000; http://localhost:5000"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward svc/hello-webapp -n hello-system 5000:5000" -NoNewWindow

while (-not (kubectl get pod -n hello-api -l app=fastapi -o name)) {
    Write-Host "Waiting for fastapi(service app) pod to be created..."
    Start-Sleep -Seconds 2
}
Write-Host "fastapi pod created!, Exposing on port 8000; http://localhost:8000"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward svc/fastapi -n hello-api 8000:8000" -NoNewWindow