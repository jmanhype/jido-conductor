#!/bin/bash

# Main run script
echo "Running template: ${TEMPLATE_NAME}"
echo "Mode: ${TEMPLATE_MODE}"
echo "Log level: ${LOG_LEVEL}"

# Simulate some work
echo "Processing data..."
sleep 2

# Generate sample output
cat << EOF > ${WORKSPACE_DIR}/output/results.json
{
  "status": "success",
  "template": "${TEMPLATE_NAME}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "results": {
    "items_processed": 42,
    "success_rate": 0.95,
    "duration_seconds": 2
  }
}
EOF

echo "Results saved to ${WORKSPACE_DIR}/output/results.json"
echo "Run completed successfully"