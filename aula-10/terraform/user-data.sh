#!/bin/bash
# Prepara a EC2 para receber deploys do pipeline CD.
# A AMI Amazon Linux 2023 já traz a AWS CLI v2 (usada no login do ECR).
set -euo pipefail
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user
docker --version
aws --version
