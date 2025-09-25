#!/bin/bash

# Archive script - runs after template execution
echo "Archiving results for template: ${TEMPLATE_NAME}"

# Create archive directory
ARCHIVE_DIR="${WORKSPACE_DIR}/archive"
mkdir -p ${ARCHIVE_DIR}

# Copy important files to archive
if [ -f "${WORKSPACE_DIR}/output/results.json" ]; then
    cp ${WORKSPACE_DIR}/output/results.json ${ARCHIVE_DIR}/
    echo "Archived results.json"
fi

# Create manifest
cat << EOF > ${ARCHIVE_DIR}/manifest.txt
Template: ${TEMPLATE_NAME}
Version: ${TEMPLATE_VERSION}
Run ID: $(basename ${WORKSPACE_DIR})
Archived at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

# Compress archive if needed
if command -v tar &> /dev/null; then
    cd ${WORKSPACE_DIR}
    tar -czf archive.tar.gz archive/
    echo "Created archive.tar.gz"
fi

echo "Archive completed successfully"