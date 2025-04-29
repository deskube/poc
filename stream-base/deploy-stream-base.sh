#!/bin/bash
# Script to correctly deploy MetalLB and Stream Base service

# Set namespace variable
NAMESPACE="deskube"

echo "======= Setting Up Stream Base Namespace and Service Account ======="
# Check if namespace exists, if not create it
if ! oc get namespace $NAMESPACE &> /dev/null; then
  echo "Creating namespace: $NAMESPACE"
  oc create namespace $NAMESPACE
fi

oc project $NAMESPACE

oc adm policy add-scc-to-user privileged -z default -n $NAMESPACE

echo "======= Deploying Stream Base ConfigMap ======="
# Check if RECEIVER_IP is defined, if not set default value
if [ -z "${RECEIVER_IP}" ]; then
  echo "RECEIVER_IP environment variable is not set."
  echo "Please set RECEIVER_IP to the IP address of the receiver."
  echo "Example: export RECEIVER_IP=<receiver_ip>"
  echo "Then run the script again."
  echo "Exiting..."
  exit 1
else
  # Check if configmap exists, if not create it
  if ! oc get configmap stream-base-config -n $NAMESPACE &> /dev/null; then
    echo "Creating configmap: stream-base-config"
    oc create configmap stream-base-config \
      --from-literal=receiver_ip=$RECEIVER_IP
  else
    echo "ConfigMap stream-base-config already exists"
    oc delete configmap stream-base-config
    oc create configmap stream-base-config \
      --from-literal=receiver_ip=$RECEIVER_IP
  fi
fi

echo "======= Deploying Stream Base Pod ======="
# Delete the pod if it exists (Pods are immutable)
if oc get pod stream-base -n $NAMESPACE &> /dev/null; then
  echo "Deleting existing stream-base pod..."
  oc delete pod stream-base -n $NAMESPACE
  sleep 5
fi

# Apply the pod
echo "Applying pod configuration..."
oc apply -f stream-base-pod.yaml -n $NAMESPACE

# Wait for the pod to be ready
echo "Waiting for stream-base pod to be ready..."
oc wait --for=condition=Ready pod/stream-base --timeout=120s

echo ""
echo "======= Success! ======="
echo "stream-base service is available in the $NAMESPACE namespace."
echo "You can exec into it with:"
echo "oc exec -it stream-base -n $NAMESPACE -- bash"
