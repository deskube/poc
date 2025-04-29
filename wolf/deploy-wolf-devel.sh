#!/bin/bash
# Script to correctly deploy Wolf Development pod

# Set namespace variable
NAMESPACE="deskube"

echo "======= Setting Up Wolf Development Namespace and Service Account ======="
# Check if namespace exists, if not create it
if ! oc get namespace $NAMESPACE &> /dev/null; then
  echo "Creating namespace: $NAMESPACE"
  oc create namespace $NAMESPACE
fi

oc project $NAMESPACE

oc adm policy add-scc-to-user privileged -z default -n $NAMESPACE

echo "======= Creating Wolf Config Directory ======="
# Create config directory if it doesn't exist
CONFIG_DIR="/home/epheo/wolf-config"
mkdir -p "$CONFIG_DIR"
echo "Wolf config will be stored in: $CONFIG_DIR"

echo "======= Deploying Wolf Development Pod ======="
# Delete the pod if it exists (Pods are immutable)
if oc get pod wolf-devel -n $NAMESPACE &> /dev/null; then
  echo "Deleting existing wolf-devel pod..."
  oc delete pod wolf-devel -n $NAMESPACE
  sleep 5
fi

# Apply the pod
echo "Applying pod configuration..."
oc apply -f wolf-devel-pod.yaml -n $NAMESPACE

# Wait for the pod to be ready
echo "Waiting for wolf-devel pod to be ready..."
oc wait --for=condition=Ready pod/wolf-devel -n $NAMESPACE --timeout=120s

echo ""
echo "======= Success! ======="
echo "wolf-devel service is available in the $NAMESPACE namespace."
echo "You can exec into it with:"
echo "oc exec -it wolf-devel -n $NAMESPACE -- bash"
echo "Configuration files are stored in: $CONFIG_DIR"
