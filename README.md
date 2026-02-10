# Claude Ghost Inspector

Automated Ghost Inspector test creation for WooCommerce sites. Deploys to Kinsta (or any WordPress host), detects your site's pages, products, and payment methods, then creates checkout flow and page screenshot tests via the Ghost Inspector API.

## Workflow Overview

```
                        DEPLOY TO SITE
                             |
                             v
                    +-----------------+
                    |   Extract repo  |
                    |   to site root  |
                    +-----------------+
                             |
                             v
                    +-----------------+
                    |  ./setup.sh     |  <-- Interactive setup
                    |  (guided)       |      Asks for: API key, site URL, suite name,
                    +-----------------+      billing details
                             |
                    Creates config/config.json
                             |
              +--------------+--------------+
              |                             |
              v                             v
   +---------------------+      +------------------------+
   | detect-payment-      |      | detect-pages.sh        |
   | methods.sh           |      | (requires wp-cli)      |
   | (requires wp-cli)    |      | Shows: pages, posts,   |
   | Shows: active        |      |   products, categories  |
   | payment gateways     |      +------------------------+
   +---------------------+                  |
              |                             |
              v                             v
   +---------------------+      +------------------------+
   | Update config.json  |      | Review detected URLs    |
   | payment_methods     |      | and confirm             |
   +---------------------+      +------------------------+
              |                             |
              v                             v
   +---------------------+      +------------------------+
   | create-tests.sh     |      | create-page-tests.sh   |
   | Creates 6 checkout  |      | Creates desktop+mobile  |
   | flow tests          |      | screenshot tests        |
   +---------------------+      +------------------------+
              |                             |
              +--------------+--------------+
                             |
                             v
                    +-----------------+
                    | list-tests.sh   |  <-- Verify tests created
                    +-----------------+
                             |
                             v
                    +-----------------+
                    | run-tests.sh    |  <-- Execute all tests
                    +-----------------+
                             |
                             v
                    +-----------------+
                    | Ghost Inspector |
                    | Dashboard       |  <-- Review results
                    +-----------------+
```

## Requirements

| Requirement | Required? | Purpose |
|-------------|-----------|---------|
| Ghost Inspector account | Yes | API access for test creation |
| Ghost Inspector API Key | Yes | Authentication ([get it here](https://app.ghostinspector.com/settings/api-access)) |
| `curl` | Yes | API requests |
| `jq` | Yes | JSON parsing |
| `bash` | Yes | Script execution |
| WP-CLI (`wp`) | Optional | Auto-detect payment methods, pages, and products |
| WooCommerce | Yes | Site must have WooCommerce with standard checkout |

### Check dependencies

```bash
# Required
curl --version
jq --version

# Optional (for auto-detection)
wp --version
```

### Install missing dependencies (Kinsta SSH)

```bash
# jq (if not available)
curl -L -o /usr/local/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64
chmod +x /usr/local/bin/jq
```

## What You Need Before Starting

Before running setup, have these ready:

1. **Ghost Inspector API Key** - from https://app.ghostinspector.com/settings/api-access
2. **Site URL** - the full HTTPS URL (e.g., `https://yourstore.com.au`)
3. **Payment method IDs** - either detected via WP-CLI or inspected from checkout page

### Billing Test Data (defaults)

The setup uses these defaults for filling checkout forms. You can change them during setup:

| Field | Default Value |
|-------|---------------|
| First Name | TEST |
| Last Name | TEST |
| Company | Blaze Commerce |
| Address | 197 Bay Street |
| City | Brighton |
| Postcode | 3186 |
| State | VIC |
| Phone | 0412345678 |
| Email | dev@blazecommerce.io |

## Quick Start

### Step 1: Deploy to site

```bash
# On Kinsta (SSH into the site)
cd /www/your-site/public/

# Clone or extract the repo
git clone https://github.com/blaze-commerce/claude-ghost-inspector.git

# Or if updating from a zip
unzip claude-ghost-inspector.zip -d claude-ghost-inspector
```

### Step 2: Run interactive setup

```bash
cd claude-ghost-inspector
./setup.sh
```

The setup wizard will walk you through:
1. Enter Ghost Inspector API Key (validated automatically)
2. Enter site URL
3. Choose suite name (auto-detected from domain)
4. Create new suite or use existing suite ID
5. Enter billing details (or press Enter for defaults)
6. Optionally create checkout tests immediately

### Step 3: Detect site content (requires WP-CLI)

```bash
# Detect available payment methods
bash scripts/detect-payment-methods.sh

# Detect pages, posts, products, categories
bash scripts/detect-pages.sh
```

Review the output and update `config/config.json` if the payment method IDs differ from defaults.

### Step 4: Create tests

```bash
# Create checkout flow tests (6 tests)
bash scripts/create-tests.sh

# Create page screenshot tests (desktop + mobile per page)
bash scripts/create-page-tests.sh
```

### Step 5: Verify and run

```bash
# List all created tests
bash scripts/list-tests.sh

# Run all tests
bash scripts/run-tests.sh
```

## What Gets Created

### Checkout Tests (via `create-tests.sh`)

| Test | Description |
|------|-------------|
| Add Product to Cart (Desktop) | Adds first product from `/shop/` to cart, verifies cart indicator |
| Checkout - Card Payment Test | Full checkout flow with card payment |
| Checkout - PayPal Button Test | Full checkout flow with PayPal |
| Checkout - Afterpay Test | Full checkout flow with Afterpay |
| Checkout - Direct Bank Transfer Test | Full checkout flow with bank transfer |
| Checkout - Pay on Account Test | Full checkout flow with pay-on-account/COD |

Each checkout test performs:
1. Navigate to `/shop/`
2. Click add-to-cart on first product
3. Navigate to `/checkout/`
4. Fill all billing fields (first name, last name, company, address, city, postcode, state, phone, email)
5. Uncheck "Ship to different address"
6. Select payment method
7. Accept terms & conditions
8. Click Place Order
9. Take screenshot of result

### Page Screenshot Tests (via `create-page-tests.sh`)

Auto-discovers and creates tests for:
- Up to 7 published pages
- Up to 3 blog posts
- Up to 3 product categories
- Up to 3 single products
- Home page

Each URL gets **two tests**: desktop (full viewport) and mobile (414x896).

## Configuration

### config/config.json

Created by `setup.sh`. Full structure:

```json
{
  "api_key": "your-ghost-inspector-api-key",
  "site_url": "https://example.com",
  "suite_id": "ghost-inspector-suite-id",
  "suite_name": "example.com",
  "billing": {
    "first_name": "TEST",
    "last_name": "TEST",
    "company": "Blaze Commerce",
    "address_1": "197 Bay Street",
    "city": "Brighton",
    "postcode": "3186",
    "state": "VIC",
    "phone": "0412345678",
    "email": "dev@blazecommerce.io"
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
```

### Common Payment Method IDs

| Gateway | Config Key | Selector ID |
|---------|-----------|-------------|
| PayPal (PPCP) | `paypal` | `payment_method_ppcp-gateway` |
| WooPayments / Stripe | `card` | `payment_method_woocommerce_payments` |
| Afterpay | `afterpay` | `payment_method_afterpay` |
| Bank Transfer | `bank_transfer` | `payment_method_bacs` |
| Cash on Delivery | `pay_on_account` | `payment_method_cod` |
| Cheque | - | `payment_method_cheque` |
| Stripe (standalone) | - | `payment_method_stripe` |

To find your site's actual IDs:
1. Run `bash scripts/detect-payment-methods.sh` (if WP-CLI available), **or**
2. Go to checkout page, inspect the payment method radio buttons, look at the `id` attribute

### Customizing Selectors

If your theme uses non-standard selectors, update the `selectors` section in `config/config.json`:

- `add_to_cart_button` - CSS selector for the add-to-cart button on `/shop/`
- `ship_to_different_checkbox` - "Ship to different address" checkbox
- `terms_checkbox` - Terms & conditions checkbox
- `place_order_button` - Place order button

### Adjusting Timeouts

If tests fail due to slow page loads, increase the timeout values (in milliseconds):

- `after_add_to_cart` - Wait after clicking add-to-cart (default: 3000ms)
- `after_page_load` - Wait after navigating to checkout (default: 3000ms)
- `after_payment_select` - Wait after selecting payment method (default: 2000ms)
- `after_terms_click` - Wait after clicking terms checkbox (default: 1000ms)
- `before_screenshot` - Wait before taking final screenshot (default: 5000ms)

## Scripts Reference

| Script | Purpose | Requires WP-CLI |
|--------|---------|-----------------|
| `setup.sh` | Interactive setup wizard, creates config | No |
| `scripts/create-tests.sh` | Create checkout flow tests from templates | No |
| `scripts/create-page-tests.sh` | Create page screenshot tests | Yes |
| `scripts/run-tests.sh` | Execute all tests in suite | No |
| `scripts/list-tests.sh` | List all tests with status | No |
| `scripts/delete-tests.sh` | Delete all tests (requires confirmation) | No |
| `scripts/detect-payment-methods.sh` | Show active payment gateways | Yes |
| `scripts/detect-pages.sh` | Show pages, posts, products, categories | Yes |

## Templates

Test templates live in `templates/`. Each is a JSON file with Ghost Inspector step definitions and `{{placeholder}}` variables that get replaced from `config/config.json`.

| Template | Test Created |
|----------|-------------|
| `add-to-cart.json` | Add Product to Cart (Desktop) |
| `checkout-card.json` | Checkout - Card Payment Test |
| `checkout-paypal.json` | Checkout - PayPal Button Test |
| `checkout-afterpay.json` | Checkout - Afterpay Test |
| `checkout-bank-transfer.json` | Checkout - Direct Bank Transfer Test |
| `checkout-pay-on-account.json` | Checkout - Pay on Account Test |
| `page-desktop.json` | Desktop screenshot (used by create-page-tests.sh) |
| `page-mobile.json` | Mobile screenshot (used by create-page-tests.sh) |

To add a new payment method test:
1. Copy an existing `checkout-*.json` template
2. Change the test name and payment method placeholder
3. Run `bash scripts/create-tests.sh`

## Updating on Kinsta

When a new version is released:

```bash
# Check current version on the site
cat VERSION

# Pull latest (if deployed via git)
git pull origin main

# Or download the release zip from GitHub
# Go to: https://github.com/blaze-commerce/claude-ghost-inspector/releases
# Download the zip and extract over existing files
```

Your `config/config.json` will not be overwritten since it's not tracked in version control.

## Releasing a New Version

Follow these steps to create a new release:

```bash
# 1. Update VERSION file
echo "1.2.0" > VERSION

# 2. Update CHANGELOG.md with new section at the top
#    Follow the Keep a Changelog format

# 3. Commit changes
git add -A
git commit -m "Release v1.2.0"

# 4. Create a tag (must match VERSION)
git tag v1.2.0

# 5. Push commit and tag
git push origin main
git push origin v1.2.0
```

The GitHub Actions release workflow will automatically:
- Verify the tag matches the VERSION file
- Extract release notes from CHANGELOG.md
- Create a GitHub Release with a deployment zip attached

### CI Pipeline

Every push and pull request runs:
- **ShellCheck** - lints all `.sh` scripts for errors and best practices
- **JSON validation** - ensures all templates and config example are valid JSON
- **Executable check** - verifies scripts have the correct permissions
- **VERSION format check** - ensures semver format (e.g., `1.2.0`)

## Cloudflare Turnstile / CAPTCHA

If checkout has Cloudflare Turnstile enabled, Ghost Inspector tests will fail on the CAPTCHA. Disable it before running tests:

```bash
# Disable Turnstile on checkout (before tests)
wp option update cfturnstile_woo_checkout ""

# Re-enable Turnstile on checkout (after tests)
wp option update cfturnstile_woo_checkout "on"
```

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `curl is required but not installed` | Missing curl | Install curl |
| `jq is required but not installed` | Missing jq | Install jq |
| `config/config.json not found` | Setup not run | Run `./setup.sh` |
| API key invalid | Wrong or expired key | Get new key from [GI settings](https://app.ghostinspector.com/settings/api-access) |
| Tests fail on "Ship to different address" | Checkbox state varies by theme | Edit `selectors.ship_to_different_checkbox` in config or remove the click step from templates |
| Payment method not found | Wrong payment method ID | Run `detect-payment-methods.sh` and update config |
| Page tests fail to create | WP-CLI not available | Install WP-CLI or create tests manually |
| Tests timeout | Site is slow | Increase values in `timeouts` section of config |

## Version History

See [CHANGELOG.md](CHANGELOG.md)

## License

MIT
