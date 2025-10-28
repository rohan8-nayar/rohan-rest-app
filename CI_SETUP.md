# CI/CD Pipeline Setup Guide

This guide will help you set up the complete CI/CD pipeline for the Student REST API application.

## Overview

The CI pipeline consists of the following stages:
1. **Build API** - Set up the Python environment and dependencies
2. **Run Tests** - Execute unit tests and generate coverage reports
3. **Code Linting** - Perform code quality checks using flake8
4. **Docker Login** - Authenticate with Docker registry
5. **Docker Build and Push** - Build and push Docker image to registry

## Prerequisites

### 1. Self-Hosted GitHub Runner Setup

#### Install GitHub Actions Runner on your local machine:

```bash
# Create a directory for the runner
mkdir actions-runner && cd actions-runner

# Download the latest runner package (replace with your OS/architecture)
curl -o actions-runner-osx-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz

# Extract the installer
tar xzf ./actions-runner-osx-x64-2.311.0.tar.gz
```

#### Configure the runner:

1. Go to your GitHub repository
2. Navigate to **Settings** > **Actions** > **Runners**
3. Click **New self-hosted runner**
4. Follow the configuration instructions and run:

```bash
# Configure the runner (use the token from GitHub)
./config.sh --url https://github.com/rohan8-nayar/rohan-rest-app --token YOUR_TOKEN

# Install and start the runner as a service
sudo ./svc.sh install
sudo ./svc.sh start
```

### 2. Docker Registry Setup

#### Option A: Docker Hub (Recommended)

1. Create a Docker Hub account at https://hub.docker.com
2. Create an Access Token:
   - Go to **Account Settings** > **Security** > **Access Tokens**
   - Click **New Access Token**
   - Give it a descriptive name like "GitHub Actions CI"
   - Copy the token (you won't see it again)

#### Option B: GitHub Container Registry

No additional setup needed - uses your GitHub token automatically.

### 3. GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

1. Go to your repository on GitHub
2. Navigate to **Settings** > **Secrets and variables** > **Actions**
3. Add the following repository secrets:

#### For Docker Hub:
- `DOCKER_HUB_USERNAME`: Your Docker Hub username
- `DOCKER_HUB_ACCESS_TOKEN`: The access token you created

#### For GitHub Container Registry (Alternative):
- No additional secrets needed (uses `GITHUB_TOKEN` automatically)

## Workflow Configuration

### Trigger Conditions

The workflow triggers on:

1. **Push to branches**: `main`, `actions`
2. **Pull requests** to `main` branch
3. **Manual trigger** via workflow_dispatch

### Path Filtering

The workflow only runs when changes are made to:
- Python files (`**.py`)
- Requirements files (`requirements*.txt`)
- Docker configuration (`Dockerfile`, `docker-compose.yml`)
- Build configuration (`Makefile`)
- Workflow files (`.github/workflows/**`)

This ensures the pipeline doesn't run for documentation or other non-code changes.

## Usage

### Automatic Triggers

The pipeline automatically runs when you:
```bash
# Push changes to main or actions branch
git add .
git commit -m "Your changes"
git push origin main
```

### Manual Trigger

1. Go to your repository on GitHub
2. Navigate to **Actions** tab
3. Select **CI Pipeline** workflow
4. Click **Run workflow**
5. Choose the environment (development/staging/production)
6. Click **Run workflow**

## Make Targets Used

The workflow uses the following make targets:

- `make test` - Run unit tests
- `make test-cov` - Run tests with coverage
- `make lint` - Perform code linting
- `make docker-build` - Build Docker image (alternative method)
- `make docker-push` - Push Docker image (alternative method)

## Docker Image Tagging Strategy

Images are tagged with:
- `latest` (for main branch)
- `<branch-name>` (for feature branches)
- `<branch-name>-<commit-sha>` (unique identifier)
- `pr-<number>` (for pull requests)

## Troubleshooting

### Common Issues

1. **Self-hosted runner not found**
   - Ensure the runner is online: `sudo ./svc.sh status`
   - Check runner labels match workflow requirements

2. **Docker login failed**
   - Verify Docker Hub credentials in GitHub secrets
   - Ensure access token has write permissions

3. **Make targets fail**
   - Check that all dependencies are in requirements-dev.txt
   - Ensure Python 3.13 is available on the runner

4. **Tests fail**
   - Run tests locally first: `make test`
   - Check for missing test dependencies

### Logs and Debugging

- View workflow logs in the **Actions** tab of your repository
- Each step shows detailed output for debugging
- Failed steps are highlighted in red

## Customization

### Using GitHub Container Registry instead of Docker Hub

Uncomment the GitHub Container Registry login section and comment out Docker Hub:

```yaml
# Use this instead of Docker Hub
- name: Log in to GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

### Adding More Environments

Modify the workflow_dispatch inputs to add more environments:

```yaml
workflow_dispatch:
  inputs:
    environment:
      type: choice
      options:
      - development
      - staging
      - production
      - testing
```

## Security Best Practices

1. **Never commit secrets** to the repository
2. **Use least-privilege access tokens** for Docker registry
3. **Regularly rotate access tokens**
4. **Monitor runner logs** for suspicious activity
5. **Keep runner software updated**

## Next Steps

After setting up the CI pipeline:

1. Test the pipeline by making a small code change
2. Verify images are pushed to your registry
3. Set up deployment pipeline (CD) for different environments
4. Configure notifications for build failures
5. Add integration tests if needed

## Support

If you encounter issues:
1. Check the GitHub Actions documentation
2. Review the workflow logs
3. Ensure all prerequisites are met
4. Test make targets locally first