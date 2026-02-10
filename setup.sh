#!/bin/bash
# Claude Ghost Inspector Setup Script
# Version: 1.0.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/config.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}           Claude Ghost Inspector Setup - v$(cat "${SCRIPT_DIR}/VERSION")${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check dependencies
command -v curl >/dev/null 2>&1 || { echo -e "${RED}Error: curl is required but not installed.${NC}" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${RED}Error: jq is required but not installed.${NC}" >&2; exit 1; }

# Check if already configured
if [[ -f "$CONFIG_FILE" ]]; then
    echo -e "${YELLOW}Existing configuration found.${NC}"
    read -rp "Do you want to reconfigure? (y/N): " reconfigure
    if [[ ! "$reconfigure" =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

# Get API Key
echo ""
echo -e "${BLUE}Step 1: Ghost Inspector API Key${NC}"
echo "Get your API key from: https://app.ghostinspector.com/settings/api-access"
echo ""
read -rp "Enter your Ghost Inspector API Key: " api_key

# Validate API key
echo -n "Validating API key... "
source "${SCRIPT_DIR}/lib/gi-api.sh"
validation=$(curl -s "https://api.ghostinspector.com/v1/suites/?apiKey=${api_key}" | jq -r '.code')
if [[ "$validation" != "SUCCESS" ]]; then
    echo -e "${RED}INVALID${NC}"
    echo "Error: API key is invalid. Please check and try again."
    exit 1
fi
echo -e "${GREEN}VALID${NC}"

# Get Site URL
echo ""
echo -e "${BLUE}Step 2: Site URL${NC}"
read -rp "Enter your site URL (e.g., https://example.com): " site_url

# Remove trailing slash
site_url="${site_url%/}"

# Validate URL format
if [[ ! "$site_url" =~ ^https?:// ]]; then
    echo -e "${RED}Error: URL must start with http:// or https://${NC}"
    exit 1
fi

# Get Suite Name
echo ""
echo -e "${BLUE}Step 3: Suite Name${NC}"
# Extract domain for default name
default_name=$(echo "$site_url" | sed -e 's|https\?://||' -e 's|/.*||')
read -rp "Enter suite name (default: ${default_name}): " suite_name
suite_name="${suite_name:-$default_name}"

# Ask about creating suite
echo ""
echo -e "${BLUE}Step 4: Ghost Inspector Suite${NC}"
echo "Options:"
echo "  1) Create a new suite"
echo "  2) Use an existing suite ID"
read -rp "Choose option (1 or 2): " suite_option

if [[ "$suite_option" == "1" ]]; then
    echo -n "Creating suite '${suite_name}'... "
    suite_response=$(curl -s -X POST "https://api.ghostinspector.com/v1/suites/?apiKey=${api_key}" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"${suite_name}\", \"startUrl\": \"${site_url}\"}")

    if [[ $(echo "$suite_response" | jq -r '.code') == "SUCCESS" ]]; then
        suite_id=$(echo "$suite_response" | jq -r '.data._id')
        echo -e "${GREEN}CREATED${NC}"
        echo "Suite ID: ${suite_id}"
    else
        echo -e "${RED}FAILED${NC}"
        echo "Error: $(echo "$suite_response" | jq -r '.message')"
        exit 1
    fi
else
    read -rp "Enter existing suite ID: " suite_id
fi

# Configure billing details
echo ""
echo -e "${BLUE}Step 5: Test Billing Details${NC}"
echo "These details will be used when filling checkout forms."
echo "(Press Enter to use defaults)"
echo ""

read -rp "First name (default: TEST): " billing_first_name
billing_first_name="${billing_first_name:-TEST}"

read -rp "Last name (default: TEST): " billing_last_name
billing_last_name="${billing_last_name:-TEST}"

read -rp "Company (default: Blaze Commerce): " billing_company
billing_company="${billing_company:-Blaze Commerce}"

read -rp "Address (default: 197 Bay Street): " billing_address
billing_address="${billing_address:-197 Bay Street}"

read -rp "City (default: Brighton): " billing_city
billing_city="${billing_city:-Brighton}"

read -rp "Postcode (default: 3186): " billing_postcode
billing_postcode="${billing_postcode:-3186}"

read -rp "State (default: VIC): " billing_state
billing_state="${billing_state:-VIC}"

read -rp "Phone (default: 0412345678): " billing_phone
billing_phone="${billing_phone:-0412345678}"

read -rp "Email (default: dev@blazecommerce.io): " billing_email
billing_email="${billing_email:-dev@blazecommerce.io}"

# Create config file
echo ""
echo -n "Creating configuration file... "

cat > "$CONFIG_FILE" << EOF
{
  "api_key": "${api_key}",
  "site_url": "${site_url}",
  "suite_id": "${suite_id}",
  "suite_name": "${suite_name}",
  "billing": {
    "first_name": "${billing_first_name}",
    "last_name": "${billing_last_name}",
    "company": "${billing_company}",
    "address_1": "${billing_address}",
    "city": "${billing_city}",
    "postcode": "${billing_postcode}",
    "state": "${billing_state}",
    "phone": "${billing_phone}",
    "email": "${billing_email}"
  },
  "payment_methods": {
    "paypal": "payment_method_ppcp-gateway",
    "card": "payment_method_woocommerce_payments",
    "afterpay": "payment_method_afterpay",
    "bank_transfer": "payment_method_bacs",
    "pay_on_account": "payment_method_cod"
  },
  "selectors": {
    "add_to_cart_button": ".products .product:first-child a.add_to_cart_button",
    "ship_to_different_checkbox": "#ship-to-different-address-checkbox",
    "terms_checkbox": "#terms, input[name=terms]",
    "place_order_button": "#place_order"
  },
  "timeouts": {
    "after_add_to_cart": 3000,
    "after_page_load": 3000,
    "after_payment_select": 2000,
    "after_terms_click": 1000,
    "before_screenshot": 5000
  }
}
EOF

echo -e "${GREEN}DONE${NC}"

# Ask about creating tests
echo ""
echo -e "${BLUE}Step 6: Create Test Cases${NC}"
read -rp "Do you want to create all test cases now? (Y/n): " create_tests

if [[ ! "$create_tests" =~ ^[Nn]$ ]]; then
    echo ""
    "${SCRIPT_DIR}/scripts/create-tests.sh"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}                         Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Configuration saved to: config/config.json"
echo ""
echo "Next steps:"
echo "  1. Review config/config.json and adjust payment method IDs if needed"
echo "  2. Run tests: ./scripts/run-tests.sh"
echo "  3. View results in Ghost Inspector dashboard"
echo ""
echo -e "Suite URL: ${BLUE}https://app.ghostinspector.com/suites/${suite_id}${NC}"
echo ""
