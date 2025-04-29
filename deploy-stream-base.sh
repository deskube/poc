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

# Create service account
echo "Creating Stream Base service account..."
oc apply -f stream-base-service-account.yaml -n $NAMESPACE

# Give the service account privileged access
echo "Granting privileged access to the service account..."
oc adm policy add-scc-to-user privileged -z stream-base-sa -n $NAMESPACE

echo "======= Deploying Stream Base Pod ======="
# Delete the pod if it exists (Pods are immutable)
if oc get pod stream-base -n $NAMESPACE &> /dev/null; then
  echo "Deleting existing stream-base pod..."
  oc delete pod stream-base -n $NAMESPACE
  sleep 5
fi

# Apply the privileged pod
echo "Applying privileged pod configuration..."
oc apply -f stream-base-pod.yaml -n $NAMESPACE

echo "======= Deploying stream-base Service ======="
# Apply the service
echo "Applying LoadBalancer service..."
oc apply -f stream-base-loadbalancer.yaml -n $NAMESPACE

echo "======= Waiting for External IP ======="
# Check if service gets an external IP
echo "Waiting for LoadBalancer to assign an external IP..."
TIMEOUT=120
COUNT=0
while [ $COUNT -lt $TIMEOUT ]; do
  EXTERNAL_IP=$(oc get service stream-base-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  if [ ! -z "$EXTERNAL_IP" ]; then
    echo "External IP assigned: $EXTERNAL_IP"
    break
  fi
  echo -n "."
  sleep 5
  COUNT=$((COUNT+1))
done

if [ -z "$EXTERNAL_IP" ]; then
  echo "Timed out waiting for external IP. Checking MetalLB status..."
  echo "MetalLB pods:"
  oc get pods -n metallb-system
  echo ""
  echo "MetalLB controller logs (if available):"
  oc logs -l component=controller -n metallb-system
  echo ""
  echo "MetalLB speaker logs (if available):"
  oc logs -l component=speaker -n metallb-system
  echo ""
  echo "IP address pools:"
  oc get ipaddresspools.metallb.io -n metallb-system -o yaml
  echo ""
  echo "L2Advertisements:"
  oc get l2advertisements.metallb.io -n metallb-system -o yaml
  echo ""
  echo "stream-base service status:"
  oc get service stream-base-service -n $NAMESPACE -o yaml
else
  echo ""
  echo "======= Success! ======="
  echo "stream-base service is available at: $EXTERNAL_IP"
  echo "RTP: $EXTERNAL_IP:48100, $EXTERNAL_IP:48200 (UDP)"
  echo "RTSP: $EXTERNAL_IP:48010 (TCP)"
  echo "HTTP: $EXTERNAL_IP:47989 (TCP)"
  echo "Control: $EXTERNAL_IP:47999 (TCP)"
  echo "HTTPS: $EXTERNAL_IP:47984 (TCP)"
  echo "You can exec into it with:"
  echo "oc exec -it stream-base -n $NAMESPACE -- bash"
fi
