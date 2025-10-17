#!/bin/bash
set -e

echo "Installing Docker and Docker Compose on Debian 12..."

# Update system
sudo apt update -y && sudo apt upgrade -y

# Remove old Docker versions if any
sudo apt remove -y docker docker-engine docker.io containerd runc || true

# Install dependencies
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker’s official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt update -y

# Install Docker Engine, CLI, containerd, and Compose plugin
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add current user to docker group
sudo usermod -aG docker $USER

# Print versions
echo "Docker version:"
docker --version
echo "Docker Compose version:"
docker compose version

echo ""
echo "Installation completed."
echo "Please log out and log back in to use Docker without sudo."
