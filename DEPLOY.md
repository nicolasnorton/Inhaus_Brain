# Deployment Guide

This guide outlines the steps to deploy the Inhaus Brain application to Google Cloud Run. These instruction assume you have the `gcloud` CLI installed and a Google Cloud Project with billing enabled.

## Prerequisites
1.  **Google Cloud SDK**: Install and initialize (`gcloud init`).
2.  **Billing**: Ensure billing is enabled for your project.
3.  **APIs**: Enable the following APIs:
    - Cloud Run API
    - Cloud Build API
    - Artifact Registry API

## Quick Start: One-Click Deployment
We have provided a helper script to automate the build and deployment process.

```bash
./deploy.sh
```

This script will:
1.  Check for `gcloud` installation.
2.  Confirm the project ID (`inhausbrain`).
3.  Submit the build to Cloud Build.
4.  Print the final service URL.

## Option 1: Manual Deployment via Cloud Build
Use the simplified `cloudbuild.yaml` configuration to build and deploy in one step.

```bash
# Submit the build to Cloud Build
gcloud builds submit --config cloudbuild.yaml .
```

## Option 2: Terraform (Infrastructure as Code)
Use Terraform to provision the service declaratively.

```bash
cd terraform

# Initialize Terraform
terraform init

# Apply the configuration (Replace YOUR_PROJECT_ID)
terraform apply -var="project_id=YOUR_PROJECT_ID"
```

## Local Testing
You can test the production container locally using Docker.

```bash
# Build the image
docker build -t inhaus-brain .

# Run container on port 8080
docker run -p 8080:8080 inhaus-brain
```

Access the app at `http://localhost:8080`.
