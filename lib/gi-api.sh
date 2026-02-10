#!/bin/bash
# Ghost Inspector API Helper Functions
# Version: 1.0.0

GI_API_BASE="https://api.ghostinspector.com/v1"

# Load config
load_config() {
    local config_file="${SCRIPT_DIR}/config/config.json"
    if [[ ! -f "$config_file" ]]; then
        echo "Error: config/config.json not found. Run setup.sh first." >&2
        exit 1
    fi

    GI_API_KEY=$(jq -r '.api_key' "$config_file")
    GI_SITE_URL=$(jq -r '.site_url' "$config_file")
    GI_SUITE_ID=$(jq -r '.suite_id' "$config_file")
    GI_SUITE_NAME=$(jq -r '.suite_name' "$config_file")

    if [[ "$GI_API_KEY" == "YOUR_GHOST_INSPECTOR_API_KEY" ]] || [[ -z "$GI_API_KEY" ]]; then
        echo "Error: API key not configured. Run setup.sh first." >&2
        exit 1
    fi
}

# Create a new suite
# Usage: gi_create_suite "Suite Name"
gi_create_suite() {
    local name="$1"
    local response

    response=$(curl -s -X POST "${GI_API_BASE}/suites/?apiKey=${GI_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"${name}\"}")

    if [[ $(echo "$response" | jq -r '.code') == "SUCCESS" ]]; then
        echo "$response" | jq -r '.data._id'
    else
        echo "Error creating suite: $(echo "$response" | jq -r '.message')" >&2
        return 1
    fi
}

# Create a test
# Usage: gi_create_test "Test Name" "suite_id" '{"steps": [...]}'
gi_create_test() {
    local name="$1"
    local suite_id="$2"
    local steps_json="$3"
    local response

    response=$(curl -s -X POST "${GI_API_BASE}/tests/?apiKey=${GI_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"${name}\", \"suite\": \"${suite_id}\", \"steps\": ${steps_json}}")

    if [[ $(echo "$response" | jq -r '.code') == "SUCCESS" ]]; then
        echo "$response" | jq -r '.data._id'
    else
        echo "Error creating test: $(echo "$response" | jq -r '.message')" >&2
        return 1
    fi
}

# Update a test
# Usage: gi_update_test "test_id" '{"steps": [...]}'
gi_update_test() {
    local test_id="$1"
    local data="$2"
    local response

    response=$(curl -s -X POST "${GI_API_BASE}/tests/${test_id}/?apiKey=${GI_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$data")

    if [[ $(echo "$response" | jq -r '.code') == "SUCCESS" ]]; then
        echo "success"
    else
        echo "Error updating test: $(echo "$response" | jq -r '.message')" >&2
        return 1
    fi
}

# Delete a test
# Usage: gi_delete_test "test_id"
gi_delete_test() {
    local test_id="$1"
    local response

    response=$(curl -s -X DELETE "${GI_API_BASE}/tests/${test_id}/?apiKey=${GI_API_KEY}")

    if [[ $(echo "$response" | jq -r '.code') == "SUCCESS" ]]; then
        echo "success"
    else
        echo "Error deleting test: $(echo "$response" | jq -r '.message')" >&2
        return 1
    fi
}

# Execute a test
# Usage: gi_execute_test "test_id"
gi_execute_test() {
    local test_id="$1"
    local response

    response=$(curl -s "${GI_API_BASE}/tests/${test_id}/execute/?apiKey=${GI_API_KEY}")

    echo "$response"
}

# Execute all tests in a suite
# Usage: gi_execute_suite "suite_id"
gi_execute_suite() {
    local suite_id="$1"
    local response

    response=$(curl -s "${GI_API_BASE}/suites/${suite_id}/execute/?apiKey=${GI_API_KEY}")

    echo "$response"
}

# List tests in a suite
# Usage: gi_list_tests "suite_id"
gi_list_tests() {
    local suite_id="$1"
    local response

    response=$(curl -s "${GI_API_BASE}/suites/${suite_id}/tests/?apiKey=${GI_API_KEY}")

    echo "$response"
}

# Get test details
# Usage: gi_get_test "test_id"
gi_get_test() {
    local test_id="$1"
    local response

    response=$(curl -s "${GI_API_BASE}/tests/${test_id}/?apiKey=${GI_API_KEY}")

    echo "$response"
}

# Validate API key
# Usage: gi_validate_key "api_key"
gi_validate_key() {
    local api_key="$1"
    local response

    response=$(curl -s "${GI_API_BASE}/suites/?apiKey=${api_key}")

    if [[ $(echo "$response" | jq -r '.code') == "SUCCESS" ]]; then
        echo "valid"
    else
        echo "invalid"
    fi
}
