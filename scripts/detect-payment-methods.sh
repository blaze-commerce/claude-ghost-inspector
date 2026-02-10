#!/bin/bash
# Detect available WooCommerce payment methods
# Version: 1.0.0

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}Detecting WooCommerce Payment Methods${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if wp-cli is available
if ! command -v wp &> /dev/null; then
    echo -e "${RED}Error: WP-CLI is not installed or not in PATH${NC}"
    echo ""
    echo "Manual detection:"
    echo "1. Go to WooCommerce → Settings → Payments"
    echo "2. Note the enabled payment methods"
    echo "3. Inspect checkout page to find payment method IDs"
    exit 1
fi

# Check if WooCommerce is active
if ! wp plugin is-active woocommerce 2>/dev/null; then
    echo -e "${RED}Error: WooCommerce is not active${NC}"
    exit 1
fi

echo "Active Payment Gateways:"
echo ""

# Get payment gateways using WP-CLI
# shellcheck disable=SC2016
wp eval '
$gateways = WC()->payment_gateways()->get_available_payment_gateways();
if (empty($gateways)) {
    echo "No payment gateways found.\n";
} else {
    foreach ($gateways as $id => $gateway) {
        $enabled = $gateway->enabled === "yes" ? "✓" : "✗";
        printf("  %s %-35s → payment_method_%s\n", $enabled, $gateway->get_title(), $id);
    }
}
' 2>/dev/null || {
    echo -e "${YELLOW}Could not detect via WP-CLI. Trying alternative method...${NC}"
    echo ""

    # Alternative: Check options directly
    wp option list --search="woocommerce_%_settings" --format=csv 2>/dev/null | while read -r line; do
        option_name=$(echo "$line" | cut -d',' -f1)
        if [[ "$option_name" == *"_settings" ]]; then
            gateway_id=$(echo "$option_name" | sed 's/woocommerce_//' | sed 's/_settings//')
            enabled=$(wp option pluck "$option_name" enabled 2>/dev/null || echo "unknown")
            if [[ "$enabled" == "yes" ]]; then
                echo "  ✓ ${gateway_id} → payment_method_${gateway_id}"
            fi
        fi
    done
}

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Copy the payment method IDs above to your config.json"
echo ""
echo "Common payment method mappings:"
echo "  PayPal (PPCP)      → payment_method_ppcp-gateway"
echo "  WooPayments/Stripe → payment_method_woocommerce_payments"
echo "  Afterpay           → payment_method_afterpay"
echo "  Bank Transfer      → payment_method_bacs"
echo "  Cash on Delivery   → payment_method_cod"
echo "  Cheque             → payment_method_cheque"
echo ""
