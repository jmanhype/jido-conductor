#!/bin/bash

# Setup script - runs before main template execution
echo "Setting up workspace for template: ${TEMPLATE_NAME}"
echo "Version: ${TEMPLATE_VERSION}"
echo "Workspace directory: ${WORKSPACE_DIR}"

# Create necessary directories
mkdir -p ${WORKSPACE_DIR}/output
mkdir -p ${WORKSPACE_DIR}/logs
mkdir -p ${WORKSPACE_DIR}/temp

# Initialize any required files
echo "{}" > ${WORKSPACE_DIR}/output/results.json

# Log environment
echo "Environment variables:"
env | grep -E "^(TEMPLATE_|WORKSPACE_)" | sort

echo "Setup completed successfully"