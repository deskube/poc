#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define variables
BC_NAME="gst-wayland-display"         # BuildConfig name
IMAGE_NAME="gst-wayland-display"      # Image name without namespace
REGISTRY="registry.desku.be"    # Your registry
TAG="latest"                    # Your desired tag
GIT_REPO="https://github.com/deskube/poc.git"  # Git repository URL
GIT_BRANCH="main"               # Git branch (default to main)

# Create image reference without any project/namespace components
# OpenShift will automatically prefix the namespace
FULL_IMAGE="${IMAGE_NAME}:${TAG}"
REGISTRY_IMAGE="${REGISTRY}/deskube/${FULL_IMAGE}"

echo "Building and pushing ${REGISTRY_IMAGE} from repository ${GIT_REPO} (branch: ${GIT_BRANCH})"

# Check if BuildConfig already exists
if oc get bc "${BC_NAME}" &>/dev/null; then
  echo "BuildConfig ${BC_NAME} already exists, starting a new build..."
  # Start a new build from the existing BuildConfig
  oc start-build "${BC_NAME}"
else
  echo "BuildConfig ${BC_NAME} does not exist, creating a new one..."

  # For Git-based builds, we'll use the repository URL as the source
  echo "Creating build config with registry: ${REGISTRY_IMAGE} from ${GIT_REPO}"

  # Ensure the builder service account exists and has the right permissions
  echo "Checking and setting up the builder service account..."
  oc get sa builder || oc create sa builder
  oc adm policy add-cluster-role-to-user system:image-builder -z builder || true
  oc adm policy add-role-to-user system:image-pusher -z builder || true

  # Create the build config with the service account specified
  oc new-build \
    --name="${BC_NAME}" \
    "${GIT_REPO}#${GIT_BRANCH}" \
    --to="${REGISTRY_IMAGE}" \
    --strategy=docker \
    --to-docker=true \
    --context-dir="gst-wayland-display"
fi


# Get the latest build name
BUILD_NAME="${BC_NAME}-$(oc get builds --sort-by=.metadata.creationTimestamp -o name | grep "${BC_NAME}" | tail -1 | awk -F/ '{print $2}')"
echo "Build started: ${BUILD_NAME}"

# Follow the logs separately
echo "Following build logs..."
oc logs -f "build/${BUILD_NAME}" || true

# Final verification
echo "Checking final build status..."
FINAL_STATUS=$(oc get "build/${BUILD_NAME}" -o jsonpath='{.status.phase}')
if [[ "$FINAL_STATUS" != "Complete" ]]; then
  echo "Build did not complete successfully."
  echo "Current status: ${FINAL_STATUS}"
  echo "Build details:"
  oc describe "build/${BUILD_NAME}"
  echo "Build logs:"
  oc logs "build/${BUILD_NAME}" --timestamps || true
  exit 1
fi

echo "Docker image ${REGISTRY_IMAGE} built and pushed successfully from Git repository ${GIT_REPO}."