#!/bin/bash

# create-clusters.sh
# This script creates three GKE clusters for the deployment pipeline

# Exit on error
set -e

# Check if PROJECT_ID and REGION are set
if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ]; then
  echo "Error: PROJECT_ID and REGION environment variables must be set"
  echo "Please run setup-environment.sh first"
  exit 1
fi

# Set the zone based on region
ZONE="${REGION}-a"
echo "Using zone: $ZONE"

# Create the three GKE clusters
echo "Creating GKE clusters..."
echo "This may take several minutes..."

echo "Creating test cluster..."
gcloud container clusters create test \
  --node-locations="$ZONE" \
  --num-nodes=1 \
  --async

echo "Creating staging cluster..."
gcloud container clusters create staging \
  --node-locations="$ZONE" \
  --num-nodes=1 \
  --async

echo "Creating prod cluster..."
gcloud container clusters create prod \
  --node-locations="$ZONE" \
  --num-nodes=1 \
  --async

echo "Check cluster status with:"
echo "gcloud container clusters list --format=\"csv(name,status)\""
