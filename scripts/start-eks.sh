#!/bin/bash

# Ensure AWS CLI is installed and configured
if ! command -v aws &> /dev/null
then
    echo "AWS CLI not found, please install and configure it."
    exit
fi

# Ensure EKS cluster name is provided
if [ -z "$1" ]; then
  echo "EKS cluster name not provided. Usage: ./start-eks.sh <eks-cluster-name> <region>"
  exit 1
fi

# Ensure AWS region is provided
if [ -z "$2" ]; then
  echo "AWS region not provided. Usage: ./start-eks.sh <eks-cluster-name> <region>"
  exit 1
fi

CLUSTER_NAME=$1
REGION=$2

# Configure kubectl to use the EKS cluster
aws eks --region $REGION update-kubeconfig --name $CLUSTER_NAME

# Deploy PostgreSQL and n8n on EKS
kubectl apply -f aws/eks/postgres/postgres-deployment.yml
kubectl apply -f aws/eks/postgres/postgres-service.yml
kubectl apply -f aws/eks/n8n/n8n-deployment.yml
kubectl apply -f aws/eks/n8n/n8n-service.yml

echo "EKS and Kubernetes services are up and running."
