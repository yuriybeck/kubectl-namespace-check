#!/usr/bin/env bash
set -e
set -o pipefail

if ! kubectl get namespaces -o json | jq -r ".items[].metadata.name" | grep prometheus;
then
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo add stable https://charts.helm.sh/stable
  helm repo update
  kubectl create namespace prometheus
  
  #generate password
  htpasswd -b -c prometheus-basic-auth prometheus ${PROM_AUTH_PASSWORD}
  kubectl create secret -n prometheus generic basic-auth --from-file=prometheus-basic-auth
  
  # deploy prometheus
  helm upgrade --install prometheus prometheus-community/prometheus -n prometheus --create-namespace -f monitoring/prometheus/values.yaml \
        --set-string server.ingress.hosts=prometheus-${CLOUD_ENVIRONMENT}.${MONITORING_DOMAIN} \
        --set-string server.ingress.tls[0].hosts=prometheus-${CLOUD_ENVIRONMENT}.${MONITORING_DOMAIN} \
  rm -rf prometheus-basic-auth
fi
