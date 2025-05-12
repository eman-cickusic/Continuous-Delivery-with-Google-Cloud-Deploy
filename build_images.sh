#!/bin/bash

# build-images.sh
# This script builds and pushes the container images to Artifact Registry

# Exit on error
set -e

# Check if PROJECT_ID and REGION are set
if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ]; then
  echo "Error: PROJECT_ID and REGION environment variables must be set"
  echo "Please run setup-environment.sh first"
  exit 1
fi

# Create the Artifact Registry repository
echo "Creating Artifact Registry repository..."
gcloud artifacts repositories create web-app \
  --description="Image registry for tutorial web app" \
  --repository-format=docker \
  --location=$REGION

# Clone the repository with the sample application
echo "Cloning sample application repository..."
cd ~/
git clone https://github.com/GoogleCloudPlatform/cloud-deploy-tutorials.git
cd cloud-deploy-tutorials
git checkout c3cae80 --quiet
cd tutorials/base

# Create the skaffold.yaml configuration
echo "Creating skaffold configuration..."
envsubst < clouddeploy-config/skaffold.yaml.template > web/skaffold.yaml
echo "Skaffold configuration created:"
cat web/skaffold.yaml

# Build the application and push to Artifact Registry
echo "Building and pushing container images..."
cd web
skaffold build --interactive=false \
  --default-repo $REGION-docker.pkg.dev/$PROJECT_ID/web-app \
  --file-output artifacts.json

echo "Build completed. Artifacts JSON file created:"
cat artifacts.json

# List the images in Artifact Registry
echo "Listing images in Artifact Registry:"
gcloud artifacts docker images list \
  $REGION-docker.pkg.dev/$PROJECT_ID/web-app \
  --include-tags

echo "Image build and push completed successfully!"
