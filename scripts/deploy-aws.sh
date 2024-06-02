#!/bin/bash

# Ensure the necessary arguments are provided
if [ -z "$1" ]; then
  echo "EC2 instance public IP not provided. Usage: ./deploy-aws.sh <ec2-instance-public-ip> <key-pair-path>"
  exit 1
fi

if [ -z "$2" ]; then
  echo "Path to key pair not provided. Usage: ./deploy-aws.sh <ec2-instance-public-ip> <key-pair-path>"
  exit 1
fi

EC2_INSTANCE_IP=$1
KEY_PAIR_PATH=$2

# Copy Docker Compose file and .env to the EC2 instance
scp -i $KEY_PAIR_PATH docker/docker-compose.yml ec2-user@$EC2_INSTANCE_IP:/home/ec2-user/docker-compose.yml
scp -i $KEY_PAIR_PATH docker/.env ec2-user@$EC2_INSTANCE_IP:/home/ec2-user/.env

# SSH into the EC2 instance and run Docker Compose
ssh -i $KEY_PAIR_PATH ec2-user@$EC2_INSTANCE_IP << EOF
  docker-compose -f /home/ec2-user/docker-compose.yml up -d
  echo "AWS EC2 Docker Compose setup is up and running."
EOF
