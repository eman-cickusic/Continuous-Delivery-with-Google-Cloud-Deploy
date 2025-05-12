# Continuous Delivery with Google Cloud Deploy

This repository demonstrates how to implement continuous delivery for a Kubernetes application using Google Cloud Deploy.

## Overview

Google Cloud Deploy is a managed service that automates delivery of your applications to a series of target environments in a defined promotion sequence. When you want to deploy your updated application, you create a release, whose lifecycle is managed by a delivery pipeline.

This project showcases:
- Setting up a multi-environment delivery pipeline (test → staging → prod)
- Building and deploying container images to Google Cloud Artifact Registry
- Creating and promoting releases through the pipeline
- Implementing approval gates for production deployments

## Prerequisites

- Google Cloud Platform account
- Project with billing enabled
- `gcloud` CLI installed
- `kubectl` installed
- `skaffold` installed

## Project Structure

```
├── README.md
├── scripts
│   ├── setup-environment.sh
│   ├── create-clusters.sh
│   ├── build-images.sh  
│   ├── create-pipeline.sh
│   └── create-release.sh
├── kubernetes-config
│   └── web-app-namespace.yaml
└── clouddeploy-config
    ├── delivery-pipeline.yaml
    ├── skaffold.yaml
    ├── target-test.yaml
    ├── target-staging.yaml
    └── target-prod.yaml
```

## Setup Instructions

### 1. Set Environment Variables

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION="us-central1"  # Change as needed
gcloud config set compute/region $REGION
```

### 2. Create GKE Clusters

Create three GKE clusters that will serve as deployment targets:

```bash
# Enable required APIs
gcloud services enable \
  container.googleapis.com \
  clouddeploy.googleapis.com

# Create clusters
gcloud container clusters create test --node-locations="us-central1-a" --num-nodes=1
gcloud container clusters create staging --node-locations="us-central1-a" --num-nodes=1
gcloud container clusters create prod --node-locations="us-central1-a" --num-nodes=1
```

### 3. Set Up Artifact Registry

```bash
# Enable Artifact Registry API
gcloud services enable artifactregistry.googleapis.com

# Create repository
gcloud artifacts repositories create web-app \
  --description="Image registry for tutorial web app" \
  --repository-format=docker \
  --location=$REGION
```

### 4. Build Application Container Images

```bash
# Enable Cloud Build API
gcloud services enable cloudbuild.googleapis.com

# Clone application source
git clone https://github.com/GoogleCloudPlatform/cloud-deploy-tutorials.git
cd cloud-deploy-tutorials
git checkout c3cae80 --quiet
cd tutorials/base

# Configure skaffold
envsubst < clouddeploy-config/skaffold.yaml.template > web/skaffold.yaml

# Build the application
cd web
skaffold build --interactive=false \
  --default-repo $REGION-docker.pkg.dev/$PROJECT_ID/web-app \
  --file-output artifacts.json
```

### 5. Create Delivery Pipeline

```bash
# Enable Google Cloud Deploy API
gcloud services enable clouddeploy.googleapis.com

# Set deploy region
gcloud config set deploy/region $REGION

# Create delivery pipeline
cp clouddeploy-config/delivery-pipeline.yaml.template clouddeploy-config/delivery-pipeline.yaml
gcloud beta deploy apply --file=clouddeploy-config/delivery-pipeline.yaml
```

### 6. Configure Deployment Targets

```bash
# Create kubectl contexts
CONTEXTS=("test" "staging" "prod")
for CONTEXT in ${CONTEXTS[@]}
do
    gcloud container clusters get-credentials ${CONTEXT} --region ${REGION}
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_${CONTEXT} ${CONTEXT}
done

# Create namespaces
for CONTEXT in ${CONTEXTS[@]}
do
    kubectl --context ${CONTEXT} apply -f kubernetes-config/web-app-namespace.yaml
done

# Create targets
for CONTEXT in ${CONTEXTS[@]}
do
    envsubst < clouddeploy-config/target-$CONTEXT.yaml.template > clouddeploy-config/target-$CONTEXT.yaml
    gcloud beta deploy apply --file clouddeploy-config/target-$CONTEXT.yaml
done
```

### 7. Create and Promote a Release

```bash
# Create the release
gcloud beta deploy releases create web-app-001 \
  --delivery-pipeline web-app \
  --release web-app-001

# Promote to prod
gcloud beta deploy releases promote \
  --delivery-pipeline web-app \
  --release web-app-001

# Approve the prod rollout
gcloud beta deploy rollouts approve web-app-001-to-prod-0001 \
  --delivery-pipeline web-app \
  --release web-app-001
```

## Verifying Deployments

After promoting releases, you can verify the application is running:

```bash
# Switch to the target context
kubectx test  # or staging, or prod

# Check resources
kubectl get all -n web-app
```

## Architecture

This project implements a three-environment pipeline:

1. **Test Environment** - Initial deployment target for every new release
2. **Staging Environment** - Pre-production environment for final testing
3. **Production Environment** - Requires manual approval before deployment

## Configuration Files

### delivery-pipeline.yaml

This configures the deployment pipeline with the three targets in sequence.

### target-*.yaml

These files define each deployment target, with the production target requiring approval.

### skaffold.yaml

Handles the building and deployment of container images.

## References

- [Google Cloud Deploy Documentation](https://cloud.google.com/deploy/docs)
- [Cloud Deploy Tutorial](https://cloud.google.com/deploy/docs/tutorials)
- [Skaffold Documentation](https://skaffold.dev/docs/)

