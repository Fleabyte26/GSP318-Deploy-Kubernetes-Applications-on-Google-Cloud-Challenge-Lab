# GSP318 - Deploy to Kubernetes: Challenge Lab
# Run in Cloud Shell. Edit the 4 lines below to match your lab panel, then paste.

export REPO="valkyrie-repository"   # Repository Name
export IMAGE="valkyrie-app"         # Docker Image
export TAG="v0.0.1"                 # Tag Name
export CLUSTER="valkyrie-dev"       # Cluster name (in Task 4 text)

export PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud config get-value compute/region)
export ZONE=$(gcloud config get-value compute/zone)
export IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE}:${TAG}"

# Task 1 - build the image

source <(gcloud storage cat gs://spls/gsp318/script.sh)

gcloud storage cp gs://spls/gsp318/valkyrie-app.tgz .
tar -xzf valkyrie-app.tgz
cd valkyrie-app
cat > Dockerfile <<'EOF'
FROM golang:1.10
WORKDIR /go/src/app
COPY source .
RUN go install -v
ENTRYPOINT ["app","-single=true","-port=8080"]
EOF
docker build -t "${IMAGE}:${TAG}" .

# >> Check my progress (Task 1)

# Task 2 - test the image

docker run -p 8080:8080 -d "${IMAGE}:${TAG}"
# >> Web Preview on port 8080

# Task 3 - push to Artifact Registry

gcloud artifacts repositories create "$REPO" --repository-format=docker --location="$REGION"
gcloud auth configure-docker "${REGION}-docker.pkg.dev"
docker tag "${IMAGE}:${TAG}" "$IMAGE_PATH"
docker push "$IMAGE_PATH"
# >> Check my progress (Task 3)

# Task 4 - deploy to Kubernetes

gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE"
sed -i "s#image: .*#image: ${IMAGE_PATH}#" k8s/deployment.yaml
kubectl create -f k8s/deployment.yaml
kubectl create -f k8s/service.yaml
kubectl get service "$CLUSTER"

# >> Check my progress (Task 4)
