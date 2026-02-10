#!/bin/bash
# List all Ghost Inspector tests in the suite
# Version: 1.0.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/config.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check config exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Error: config/config.json not found. Run setup.sh first.${NC}"
    exit 1
fi

# Load config
API_KEY=$(jq -r '.api_key' "$CONFIG_FILE")
SUITE_ID=$(jq -r '.suite_id' "$CONFIG_FILE")
SUITE_NAME=$(jq -r '.suite_name' "$CONFIG_FILE")

echo ""
echo -e "${BLUE}Ghost Inspector Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "Suite: ${SUITE_NAME}"
echo ""

# Get tests
response=$(curl -s "https://api.ghostinspector.com/v1/suites/${SUITE_ID}/tests/?apiKey=${API_KEY}")

if [[ $(echo "$response" | jq -r '.code') == "SUCCESS" ]]; then
    count=$(echo "$response" | jq '.data | length')
    echo "Tests (${count}):"
    echo ""

    echo "$response" | jq -r '.data[] | "  [\(._id)] \(.name) - \(if .passing then "✓ passing" else "✗ failing" end)"'

    echo ""
    echo "Suite URL: https://app.ghostinspector.com/suites/${SUITE_ID}"
else
    echo -e "${RED}Error fetching tests${NC}"
    echo "$(echo "$response" | jq -r '.message')"
    exit 1
fi

echo ""
