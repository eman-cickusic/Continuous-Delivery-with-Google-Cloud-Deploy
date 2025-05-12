#!/bin/bash

# create-pipeline.sh
# This script creates the Cloud Deploy pipeline and targets

# Exit on error
set -e

# Check if PROJECT_ID and REGION are set
if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ]; then
  echo "Error: PROJECT_ID and REGION environment variables must be set"
  echo "Please run setup-environment.sh first"
  exit 1
fi

# Set the deploy region
echo "Setting deploy region to $REGION"
gcloud config set deploy/region $REGION

# Create the delivery pipeline
echo "Creating delivery pipeline configuration..."
cp clouddeploy-config/delivery-pipeline.yaml.template clouddeploy-config/delivery-pipeline.yaml
gcloud beta deploy apply --file=clouddeploy-config/delivery-pipeline.yaml

# Verify the delivery pipeline was created
echo "Verifying delivery pipeline..."
gcloud beta deploy delivery-pipelines describe web-app

# Set up contexts for each cluster
echo "Setting up kubectl contexts for clusters..."
CONTEXTS=("test" "staging" "prod")
for CONTEXT in ${CONTEXTS[@]}
do
    echo "Getting credentials for $CONTEXT cluster..."
    gcloud container clusters get-credentials ${CONTEXT} --region ${REGION}
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_${CONTEXT} ${CONTEXT}
done

# Create a namespace in each cluster
echo "Creating namespaces in each cluster..."
for CONTEXT in ${CONTEXTS[@]}
do
    echo "Creating namespace in $CONTEXT cluster..."
    kubectl --context ${CONTEXT} apply -f kubernetes-config/web-app-namespace.yaml
done

# Create the targets
echo "Creating delivery pipeline targets..."
for CONTEXT in ${CONTEXTS[@]}
do
    echo "Creating $CONTEXT target..."
    envsubst < clouddeploy-config/target-$CONTEXT.yaml.template > clouddeploy-config/target-$CONTEXT.yaml
    gcloud beta deploy apply --file clouddeploy-config/target-$CONTEXT.yaml
done

# List the targets
echo "Listing targets:"
gcloud beta deploy targets list

echo "Delivery pipeline and targets created successfully!"
