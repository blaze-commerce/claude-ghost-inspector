#!/bin/bash
# Delete all Ghost Inspector tests in the suite
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
echo -e "${RED}Delete All Ghost Inspector Tests${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "Suite: ${SUITE_NAME}"
echo ""

# Confirm
echo -e "${YELLOW}WARNING: This will delete ALL tests in this suite!${NC}"
read -p "Are you sure? Type 'DELETE' to confirm: " confirm

if [[ "$confirm" != "DELETE" ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""

# Get tests
response=$(curl -s "https://api.ghostinspector.com/v1/suites/${SUITE_ID}/tests/?apiKey=${API_KEY}")
tests=$(echo "$response" | jq -r '.data[]._id')

# Delete each test
for test_id in $tests; do
    echo -n "Deleting ${test_id}... "
    delete_response=$(curl -s -X DELETE "https://api.ghostinspector.com/v1/tests/${test_id}/?apiKey=${API_KEY}")

    if [[ $(echo "$delete_response" | jq -r '.code') == "SUCCESS" ]]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
    fi
done

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
