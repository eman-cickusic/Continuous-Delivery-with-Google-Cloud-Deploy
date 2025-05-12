#!/bin/bash

# create-release.sh
# This script creates a release and promotes it through the pipeline

# Exit on error
set -e

# Check if PROJECT_ID and REGION are set
if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ]; then
  echo "Error: PROJECT_ID and REGION environment variables must be set"
  echo "Please run setup-environment.sh first"
  exit 1
fi

# Get the release name from command line or use default
RELEASE_NAME=${1:-"web-app-001"}
echo "Creating release: $RELEASE_NAME"

# Create the release
echo "Creating release..."
gcloud beta deploy releases create $RELEASE_NAME \
  --delivery-pipeline web-app \
  --build-artifacts web/artifacts.json \
  --source web/

# Wait for initial rollout to complete
echo "Waiting for initial rollout to complete..."
sleep 30

# Check the status of the rollout
echo "Checking rollout status..."
gcloud beta deploy rollouts list \
  --delivery-pipeline web-app \
  --release $RELEASE_NAME

# Ask if the user wants to promote to staging
read -p "Do you want to promote to staging? (y/n): " PROMOTE_STAGING
if [[ $PROMOTE_STAGING == "y" || $PROMOTE_STAGING == "Y" ]]; then
  echo "Promoting to staging..."
  gcloud beta deploy releases promote \
    --delivery-pipeline web-app \
    --release $RELEASE_NAME
  
  # Wait for staging rollout to complete
  echo "Waiting for staging rollout to complete..."
  sleep 30
  
  # Check the status again
  echo "Checking rollout status..."
  gcloud beta deploy rollouts list \
    --delivery-pipeline web-app \
    --release $RELEASE_NAME
fi

# Ask if the user wants to promote to prod
read -p "Do you want to promote to prod? (y/n): " PROMOTE_PROD
if [[ $PROMOTE_PROD == "y" || $PROMOTE_PROD == "Y" ]]; then
  echo "Promoting to prod..."
  gcloud beta deploy releases promote \
    --delivery-pipeline web-app \
    --release $RELEASE_NAME
  
  # Wait for prod rollout to request approval
  echo "Waiting for prod rollout to request approval..."
  sleep 30
  
  # Check the status again
  echo "Checking rollout status..."
  gcloud beta deploy rollouts list \
    --delivery-pipeline web-app \
    --release $RELEASE_NAME
  
  # Get the rollout name for approval
  ROLLOUT_NAME="${RELEASE_NAME}-to-prod-0001"
  
  # Ask if the user wants to approve the prod rollout
  read -p "Do you want to approve the prod rollout? (y/n): " APPROVE_PROD
  if [[ $APPROVE_PROD == "y" || $APPROVE_PROD == "Y" ]]; then
    echo "Approving prod rollout..."
    gcloud beta deploy rollouts approve $ROLLOUT_NAME \
      --delivery-pipeline web-app \
      --release $RELEASE_NAME
    
    # Wait for prod deployment to complete
    echo "Waiting for prod deployment to complete..."
    sleep 30
    
    # Final status check
    echo "Final rollout status:"
    gcloud beta deploy rollouts list \
      --delivery-pipeline web-app \
      --release $RELEASE_NAME
  fi
fi

echo "Release management completed!"
