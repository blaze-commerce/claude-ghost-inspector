#!/bin/bash
# Detect available pages, posts, products for testing
# Version: 1.0.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if wp-cli is available
if ! command -v wp &> /dev/null; then
    echo -e "${RED}Error: WP-CLI is not installed or not in PATH${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Detecting WordPress Content for Testing${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Detect Pages
echo -e "${GREEN}Pages (published):${NC}"
wp post list --post_type=page --post_status=publish --fields=ID,post_name,post_title --format=table 2>/dev/null | head -15
echo ""

# Count pages
PAGE_COUNT=$(wp post list --post_type=page --post_status=publish --format=count 2>/dev/null)
echo "Total pages: ${PAGE_COUNT}"
echo ""

# Detect Blog Posts
echo -e "${GREEN}Blog Posts (published):${NC}"
POST_COUNT=$(wp post list --post_type=post --post_status=publish --format=count 2>/dev/null)
if [[ "$POST_COUNT" -gt 0 ]]; then
    wp post list --post_type=post --post_status=publish --fields=ID,post_name,post_title --format=table 2>/dev/null | head -8
    echo ""
    echo "Total posts: ${POST_COUNT}"
else
    echo "No blog posts found."
fi
echo ""

# Detect Product Categories
echo -e "${GREEN}Product Categories:${NC}"
if wp plugin is-active woocommerce 2>/dev/null; then
    wp term list product_cat --fields=term_id,slug,name --format=table 2>/dev/null | head -10
    CAT_COUNT=$(wp term list product_cat --format=count 2>/dev/null)
    echo ""
    echo "Total categories: ${CAT_COUNT}"
else
    echo "WooCommerce not active."
fi
echo ""

# Detect Products
echo -e "${GREEN}Products (published):${NC}"
if wp plugin is-active woocommerce 2>/dev/null; then
    wp post list --post_type=product --post_status=publish --fields=ID,post_name,post_title --format=table 2>/dev/null | head -8
    PRODUCT_COUNT=$(wp post list --post_type=product --post_status=publish --format=count 2>/dev/null)
    echo ""
    echo "Total products: ${PRODUCT_COUNT}"
else
    echo "WooCommerce not active."
fi
echo ""

# Generate recommended test URLs
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Recommended Test URLs:${NC}"
echo ""

echo "Desktop Pages:"
wp post list --post_type=page --post_status=publish --field=post_name 2>/dev/null | head -7 | while read slug; do
    echo "  /${slug}/"
done
echo ""

if [[ "$POST_COUNT" -gt 0 ]]; then
    echo "Blog Posts (3):"
    wp post list --post_type=post --post_status=publish --field=post_name 2>/dev/null | head -3 | while read slug; do
        echo "  /${slug}/"
    done
    echo ""
fi

if wp plugin is-active woocommerce 2>/dev/null; then
    echo "Product Categories (3):"
    wp term list product_cat --field=slug 2>/dev/null | head -3 | while read slug; do
        echo "  /product-category/${slug}/"
    done
    echo ""

    echo "Single Products (3):"
    wp post list --post_type=product --post_status=publish --field=post_name 2>/dev/null | head -3 | while read slug; do
        echo "  /product/${slug}/"
    done
    echo ""
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Use these URLs when running create-page-tests.sh"
echo ""
