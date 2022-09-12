#!/bin/bash

# wait fo k8s ready
while ! kubectl get nodes | grep -w "Ready"; do
  echo "WAIT FOR NODES READY"
  sleep 1
done
touch /ks/.k8sfinished

# allow pods to run on controlplane
kubectl taint nodes controlplane node-role.kubernetes.io/master:NoSchedule-
kubectl taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule-

# install Istio
export ISTIO_VERSION=1.15.0
curl -L https://istio.io/downloadIstio | TARGET_ARCH=x86_64 sh -
cp istio-1.15.0/bin/istioctl /usr/local/bin
istioctl install -f install-manifest.yaml -y
istioctl verify-install

# install addons
kubectl apply -f istio-1.15.0/samples/addons
kubectl rollout status deployment/kiali -n istio-system

# mark init finished
touch /ks/.initfinished

cat << EOF >> ~/.bashrc

set -o vi

EOF
