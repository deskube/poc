#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define variables
BC_NAME="streamer-base"         # BuildConfig name
IMAGE_NAME="streamer-base"      # Image name without namespace
REGISTRY="registry.desku.be"    # Your registry
TAG="latest"                    # Your desired tag
GIT_REPO="https://github.com/deskube/poc.git"  # Git repository URL
GIT_BRANCH="main"               # Git branch (default to main)

# Create image reference without any project/namespace components
# OpenShift will automatically prefix the namespace
FULL_IMAGE="${IMAGE_NAME}:${TAG}"
REGISTRY_IMAGE="${REGISTRY}/deskube/${FULL_IMAGE}"

echo "Building and pushing ${REGISTRY_IMAGE} from repository ${GIT_REPO} (branch: ${GIT_BRANCH})"

# Always clean up the old BuildConfig and ImageStream to avoid any configuration issues
echo "Removing any existing BuildConfig and ImageStream for ${BC_NAME}..."
oc delete bc "${BC_NAME}" --ignore-not-found=true
oc delete is "${BC_NAME}" --ignore-not-found=true

# Create a fresh BuildConfig with minimal options
echo "Creating new BuildConfig ${BC_NAME}..."

# For Git-based builds, we'll use the repository URL as the source
echo "Creating build config with registry: ${REGISTRY_IMAGE} from ${GIT_REPO}"
oc new-build \
  --name="${BC_NAME}" \
  "${GIT_REPO}#${GIT_BRANCH}" \
  --to="${REGISTRY_IMAGE}" \
  --strategy=docker \
  --to-docker=true

# Start the build and follow the logs
echo "Starting build from Git repository..."
BUILD_NAME=$(oc start-build "${BC_NAME}" --follow)
echo "Build started: ${BUILD_NAME}"

# Final verification
FINAL_STATUS=$(oc get "${BUILD_NAME}" -o jsonpath='{.status.phase}')
if [[ "$FINAL_STATUS" != "Complete" ]]; then
  echo "Build did not complete within the expected time."
  echo "Current status: ${FINAL_STATUS}"
  echo "Build details:"
  oc describe "${BUILD_NAME}"
  echo "Build logs:"
  oc logs "${BUILD_NAME}" --timestamps
  exit 1
fi

echo "Docker image ${REGISTRY_IMAGE} built and pushed successfully from Git repository ${GIT_REPO}."