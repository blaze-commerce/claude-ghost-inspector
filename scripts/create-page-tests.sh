#!/bin/bash
# Create Ghost Inspector page/screenshot tests
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

# Check wp-cli
if ! command -v wp &> /dev/null; then
    echo -e "${RED}Error: WP-CLI is required for auto-detection.${NC}"
    exit 1
fi

# Load config
API_KEY=$(jq -r '.api_key' "$CONFIG_FILE")
SUITE_ID=$(jq -r '.suite_id' "$CONFIG_FILE")

echo ""
echo -e "${BLUE}Creating Page Screenshot Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to create a test
create_page_test() {
    local name="$1"
    local url="$2"
    local viewport="$3"  # null for desktop, or '{"width":414,"height":896}' for mobile

    echo -n "  Creating: ${name}... "

    local viewport_json="null"
    if [[ "$viewport" != "null" ]]; then
        viewport_json="$viewport"
    fi

    local response=$(curl -s -X POST "https://api.ghostinspector.com/v1/tests/?apiKey=${API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"${name}\",
            \"suite\": \"${SUITE_ID}\",
            \"viewportSize\": ${viewport_json},
            \"steps\": [
                {\"sequence\": 0, \"command\": \"open\", \"target\": \"\", \"value\": \"${url}\"},
                {\"sequence\": 1, \"command\": \"screenshot\", \"target\": \"\", \"value\": \"\"}
            ]
        }")

    if [[ $(echo "$response" | jq -r '.code') == "SUCCESS" ]]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        echo "    Error: $(echo "$response" | jq -r '.message')"
    fi
}

# Collect URLs
declare -a DESKTOP_URLS
declare -a DESKTOP_NAMES

echo -e "${YELLOW}Detecting content...${NC}"
echo ""

# 1. Pages (up to 7)
echo "Pages:"
PAGE_COUNT=0
while IFS= read -r line; do
    if [[ $PAGE_COUNT -lt 7 ]]; then
        slug=$(echo "$line" | awk '{print $1}')
        title=$(echo "$line" | cut -d' ' -f2-)
        if [[ -n "$slug" && "$slug" != "post_name" ]]; then
            DESKTOP_URLS+=("/${slug}/")
            DESKTOP_NAMES+=("/${slug}/")
            echo "  /${slug}/"
            ((PAGE_COUNT++))
        fi
    fi
done < <(wp post list --post_type=page --post_status=publish --fields=post_name,post_title --format=table 2>/dev/null | tail -n +2)
echo "  Found: ${PAGE_COUNT} pages"
echo ""

# 2. Blog Posts (up to 3)
echo "Blog Posts:"
POST_COUNT=$(wp post list --post_type=post --post_status=publish --format=count 2>/dev/null || echo "0")
if [[ "$POST_COUNT" -gt 0 ]]; then
    ADDED=0
    while IFS= read -r slug; do
        if [[ $ADDED -lt 3 && -n "$slug" ]]; then
            DESKTOP_URLS+=("/${slug}/")
            DESKTOP_NAMES+=("/${slug}/")
            echo "  /${slug}/"
            ((ADDED++))
        fi
    done < <(wp post list --post_type=post --post_status=publish --field=post_name 2>/dev/null)
    echo "  Found: ${ADDED} posts"
else
    echo "  No posts found - adding 3 more pages instead"
    EXTRA=0
    while IFS= read -r slug; do
        if [[ $EXTRA -lt 3 && -n "$slug" ]]; then
            # Check if not already added
            if [[ ! " ${DESKTOP_URLS[@]} " =~ " /${slug}/ " ]]; then
                DESKTOP_URLS+=("/${slug}/")
                DESKTOP_NAMES+=("/${slug}/")
                echo "  /${slug}/"
                ((EXTRA++))
            fi
        fi
    done < <(wp post list --post_type=page --post_status=publish --field=post_name 2>/dev/null | tail -n +8)
fi
echo ""

# 3. Product Categories (up to 3)
echo "Product Categories:"
if wp plugin is-active woocommerce 2>/dev/null; then
    ADDED=0
    while IFS= read -r slug; do
        if [[ $ADDED -lt 3 && -n "$slug" ]]; then
            DESKTOP_URLS+=("/product-category/${slug}/")
            DESKTOP_NAMES+=("/product-category/${slug}/")
            echo "  /product-category/${slug}/"
            ((ADDED++))
        fi
    done < <(wp term list product_cat --field=slug 2>/dev/null)
    echo "  Found: ${ADDED} categories"
else
    echo "  WooCommerce not active"
fi
echo ""

# 4. Single Products (up to 3)
echo "Single Products:"
if wp plugin is-active woocommerce 2>/dev/null; then
    ADDED=0
    while IFS= read -r slug; do
        if [[ $ADDED -lt 3 && -n "$slug" ]]; then
            DESKTOP_URLS+=("/product/${slug}/")
            DESKTOP_NAMES+=("/product/${slug}/")
            echo "  /product/${slug}/"
            ((ADDED++))
        fi
    done < <(wp post list --post_type=product --post_status=publish --field=post_name 2>/dev/null)
    echo "  Found: ${ADDED} products"
else
    echo "  WooCommerce not active"
fi
echo ""

# Add Home page if not already included
HOME_ADDED=false
for url in "${DESKTOP_URLS[@]}"; do
    if [[ "$url" == "/" || "$url" == "/home/" ]]; then
        HOME_ADDED=true
        break
    fi
done
if [[ "$HOME_ADDED" == false ]]; then
    DESKTOP_URLS=("/" "${DESKTOP_URLS[@]}")
    DESKTOP_NAMES=("Desktop: Home" "${DESKTOP_NAMES[@]}")
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Total URLs to test: ${#DESKTOP_URLS[@]}"
echo "Tests to create: $((${#DESKTOP_URLS[@]} * 2)) (desktop + mobile)"
echo ""

read -p "Continue? (Y/n): " confirm
if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo -e "${GREEN}Creating Desktop Tests:${NC}"
for i in "${!DESKTOP_URLS[@]}"; do
    url="${DESKTOP_URLS[$i]}"
    name="${DESKTOP_NAMES[$i]}"
    create_page_test "$name" "$url" "null"
done

echo ""
echo -e "${GREEN}Creating Mobile Tests:${NC}"
for i in "${!DESKTOP_URLS[@]}"; do
    url="${DESKTOP_URLS[$i]}"
    name="Mobile: ${DESKTOP_NAMES[$i]}"
    create_page_test "$name" "$url" '{"width":414,"height":896}'
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Done!${NC}"
echo ""
echo "View tests at: https://app.ghostinspector.com/suites/${SUITE_ID}"
echo ""
