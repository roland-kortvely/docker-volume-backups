#!/bin/bash
#
# Docker Build Script for Docker Volume Backup Script
# Author: Roland Körtvely
# Date: May 25, 2023
#

# Constants
image_name="rolandkortvely/docker-volume-backup"
dockerfile_path="Dockerfile"

# Store the current directory
current_dir=$(pwd)

# Prompt for the version with "latest" as the default
read -p "Enter the version (default: latest): " version
version=${version:-latest}

# Build the Docker image
docker build -t "$image_name:$version" -f "$dockerfile_path" .

# Set the current directory back to the original
cd "$current_dir" || exit

# Display image information
echo "Container Image Information:"
echo "Image Name: $image_name:$version"

# Prompt to push the image
read -p "Do you want to push the image to the registry? [y/N]: " push_choice
if [[ $push_choice =~ ^[Yy]$ ]]; then
    docker push "$image_name:$version"
    echo "Image successfully pushed to the registry."
fi
