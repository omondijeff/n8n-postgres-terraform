#!/bin/bash

# Start Minikube
minikube start

# Deploy PostgreSQL and n8n
kubectl apply -f kubernetes/postgres/postgres-deployment.yml
kubectl apply -f kubernetes/postgres/postgres-service.yml
kubectl apply -f kubernetes/n8n/n8n-deployment.yml
kubectl apply -f kubernetes/n8n/n8n-service.yml

echo "Minikube and Kubernetes services are up and running."
