# Changelog

All notable changes to this project will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.1.0] - 2026-02-09

### Added
- GitHub Actions CI workflow (shellcheck linting, JSON validation, executable checks)
- GitHub Actions release workflow (auto-creates GitHub release + deployment zip on tag push)
- `CODEOWNERS` file - all PRs require review from @jarutosurano
- Pull request template with checklist
- `.gitignore` to exclude `config/config.json` and OS/editor files

### Changed
- Comprehensive README rewrite with:
  - Visual ASCII workflow diagram
  - Requirements table with required vs optional dependencies
  - Pre-start checklist
  - Step-by-step Kinsta deployment guide
  - Full configuration reference (payment methods, selectors, timeouts)
  - Scripts and templates reference tables
  - Troubleshooting table

### Fixed
- CHANGELOG now lists correct scripts (previously referenced non-existent `create-suite.sh`)

## [1.0.0] - 2026-02-10

### Added
- Initial release
- Interactive setup script (`setup.sh`)
- Test templates for WooCommerce checkout:
  - Add Product to Cart (Desktop)
  - Checkout - PayPal Button Test
  - Checkout - Card Payment Test
  - Checkout - Afterpay Test
  - Checkout - Direct Bank Transfer Test
  - Checkout - Pay on Account Test
- Helper scripts:
  - `create-tests.sh` - Create tests from templates
  - `create-page-tests.sh` - Create page screenshot tests
  - `run-tests.sh` - Execute all tests
  - `list-tests.sh` - List tests in suite
  - `delete-tests.sh` - Remove all tests
  - `detect-payment-methods.sh` - Detect WooCommerce payment gateways
  - `detect-pages.sh` - Detect pages, posts, products, categories
- Configuration system with `config.example.json`
- API helper library (`lib/gi-api.sh`)
- Page screenshot templates (desktop + mobile)

### Notes
- Based on test cases developed for beaufortanimalsupplies.com.au
- Supports standard WooCommerce checkout flow
- Billing form uses TEST/TEST name for easy order identification
