#!/bin/bash

# Start Minikube
minikube start

# Deploy PostgreSQL
kubectl apply -f kubernetes/postgres/postgres-deployment.yml --validate=false
kubectl apply -f kubernetes/postgres/postgres-service.yml --validate=false

# Deploy n8n
kubectl apply -f kubernetes/n8n/n8n-deployment.yml --validate=false
kubectl apply -f kubernetes/n8n/n8n-service.yml --validate=false

# Deploy Adminer
kubectl apply -f kubernetes/adminer/adminer-deployment.yml --validate=false
kubectl apply -f kubernetes/adminer/adminer-service.yml --validate=false

echo "Minikube and Kubernetes services are up and running."

# Optionally, retrieve and print URLs for services
n8n_url=$(minikube service n8n-service --url)
adminer_url=$(minikube service adminer-service --url)

echo "n8n is accessible at: $n8n_url"
echo "Adminer is accessible at: $adminer_url"
