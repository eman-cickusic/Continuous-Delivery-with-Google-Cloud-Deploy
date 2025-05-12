#!/bin/bash

# setup-environment.sh
# This script sets up the environment variables needed for the project

# Exit on error
set -e

# Set the project ID and region
export PROJECT_ID=$(gcloud config get-value project)
export REGION="us-central1"  # Change this to your preferred region
echo "Setting compute region to $REGION"
gcloud config set compute/region $REGION

# Enable required APIs
echo "Enabling required Google Cloud APIs..."
gcloud services enable container.googleapis.com
gcloud services enable clouddeploy.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com

echo "Environment setup complete!"
echo "PROJECT_ID: $PROJECT_ID"
echo "REGION: $REGION"
