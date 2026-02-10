#!/bin/bash
# Create Ghost Inspector tests from templates
# Version: 1.0.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/config.json"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
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

# Load billing details
BILLING_FIRST_NAME=$(jq -r '.billing.first_name' "$CONFIG_FILE")
BILLING_LAST_NAME=$(jq -r '.billing.last_name' "$CONFIG_FILE")
BILLING_COMPANY=$(jq -r '.billing.company' "$CONFIG_FILE")
BILLING_ADDRESS=$(jq -r '.billing.address_1' "$CONFIG_FILE")
BILLING_CITY=$(jq -r '.billing.city' "$CONFIG_FILE")
BILLING_POSTCODE=$(jq -r '.billing.postcode' "$CONFIG_FILE")
BILLING_STATE=$(jq -r '.billing.state' "$CONFIG_FILE")
BILLING_PHONE=$(jq -r '.billing.phone' "$CONFIG_FILE")
BILLING_EMAIL=$(jq -r '.billing.email' "$CONFIG_FILE")

# Load payment methods
PM_PAYPAL=$(jq -r '.payment_methods.paypal' "$CONFIG_FILE")
PM_CARD=$(jq -r '.payment_methods.card' "$CONFIG_FILE")
PM_AFTERPAY=$(jq -r '.payment_methods.afterpay' "$CONFIG_FILE")
PM_BANK=$(jq -r '.payment_methods.bank_transfer' "$CONFIG_FILE")
PM_COD=$(jq -r '.payment_methods.pay_on_account' "$CONFIG_FILE")

# Load selectors
SEL_ADD_TO_CART=$(jq -r '.selectors.add_to_cart_button' "$CONFIG_FILE")
SEL_SHIP_DIFF=$(jq -r '.selectors.ship_to_different_checkbox' "$CONFIG_FILE")
SEL_TERMS=$(jq -r '.selectors.terms_checkbox' "$CONFIG_FILE")
SEL_PLACE_ORDER=$(jq -r '.selectors.place_order_button' "$CONFIG_FILE")

# Load timeouts
TO_ADD_CART=$(jq -r '.timeouts.after_add_to_cart' "$CONFIG_FILE")
TO_PAGE_LOAD=$(jq -r '.timeouts.after_page_load' "$CONFIG_FILE")
TO_PAYMENT=$(jq -r '.timeouts.after_payment_select' "$CONFIG_FILE")
TO_TERMS=$(jq -r '.timeouts.after_terms_click' "$CONFIG_FILE")
TO_SCREENSHOT=$(jq -r '.timeouts.before_screenshot' "$CONFIG_FILE")

echo ""
echo -e "${BLUE}Creating Ghost Inspector Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to process template and create test
create_test() {
    local template_file="$1"
    local test_name
    test_name=$(jq -r '.name' "$template_file")

    echo -n "Creating: ${test_name}... "

    # Read template and replace placeholders
    local steps
    steps=$(jq '.steps' "$template_file" | \
        sed "s/{{add_to_cart_button}}/${SEL_ADD_TO_CART//\//\\/}/g" | \
        sed "s/{{ship_to_different_checkbox}}/${SEL_SHIP_DIFF//\//\\/}/g" | \
        sed "s/{{terms_checkbox}}/${SEL_TERMS//\//\\/}/g" | \
        sed "s/{{place_order_button}}/${SEL_PLACE_ORDER//\//\\/}/g" | \
        sed "s/{{billing_first_name}}/${BILLING_FIRST_NAME}/g" | \
        sed "s/{{billing_last_name}}/${BILLING_LAST_NAME}/g" | \
        sed "s/{{billing_company}}/${BILLING_COMPANY}/g" | \
        sed "s/{{billing_address_1}}/${BILLING_ADDRESS}/g" | \
        sed "s/{{billing_city}}/${BILLING_CITY}/g" | \
        sed "s/{{billing_postcode}}/${BILLING_POSTCODE}/g" | \
        sed "s/{{billing_state}}/${BILLING_STATE}/g" | \
        sed "s/{{billing_phone}}/${BILLING_PHONE}/g" | \
        sed "s/{{billing_email}}/${BILLING_EMAIL}/g" | \
        sed "s/{{payment_method_paypal}}/${PM_PAYPAL}/g" | \
        sed "s/{{payment_method_card}}/${PM_CARD}/g" | \
        sed "s/{{payment_method_afterpay}}/${PM_AFTERPAY}/g" | \
        sed "s/{{payment_method_bank_transfer}}/${PM_BANK}/g" | \
        sed "s/{{payment_method_pay_on_account}}/${PM_COD}/g" | \
        sed "s/{{after_add_to_cart}}/${TO_ADD_CART}/g" | \
        sed "s/{{after_page_load}}/${TO_PAGE_LOAD}/g" | \
        sed "s/{{after_payment_select}}/${TO_PAYMENT}/g" | \
        sed "s/{{after_terms_click}}/${TO_TERMS}/g" | \
        sed "s/{{before_screenshot}}/${TO_SCREENSHOT}/g")

    # Create test via API
    local response
    response=$(curl -s -X POST "https://api.ghostinspector.com/v1/tests/?apiKey=${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"${test_name}\", \"suite\": \"${SUITE_ID}\", \"steps\": ${steps}}")

    if [[ $(echo "$response" | jq -r '.code') == "SUCCESS" ]]; then
        local test_id
        test_id=$(echo "$response" | jq -r '.data._id')
        echo -e "${GREEN}OK${NC} (${test_id})"
    else
        echo -e "${RED}FAILED${NC}"
        echo "  Error: $(echo "$response" | jq -r '.message')"
    fi
}

# Create all tests
for template in "${TEMPLATES_DIR}"/*.json; do
    if [[ -f "$template" ]]; then
        create_test "$template"
    fi
done

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo "View tests at: https://app.ghostinspector.com/suites/${SUITE_ID}"
echo ""
