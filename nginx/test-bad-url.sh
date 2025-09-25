#!/usr/bin/env bash

# Tests various path traversal and injection attacks

if [[ $# -ge 1 ]]; then
  BASE_URL="$1"
  if ! [[ "${BASE_URL}" =~ ^https?://([^:/]+)(:([0-9]+))? ]]; then
    echo "Invalid URL: ${BASE_URL}" >&2
    exit 1
  fi
else
  echo "Usage: $0 BASE_URL" >&2
  exit 1
fi

echo "Testing against: ${BASE_URL}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_attack() {
    local name="$1"
    local path="$2"
    local expected="$3"

    echo -n "Testing ${name}... "

    response=$(curl -skI --path-as-is "${BASE_URL}${path}" 2>/dev/null | head -1 | grep -o "HTTP/[0-9.]* [0-9]*" | cut -d' ' -f2 || true)

    if [[ "${response}" = "${expected}" ]]; then
        if [[ "${expected}" = "400" ]]; then
            echo -e "${GREEN}BLOCKED (${response})${NC}"
        else
            echo -e "${YELLOW}ALLOWED (${response})${NC}"
        fi
    else
        echo -e "${RED}UNEXPECTED (${response}, expected ${expected})${NC}"
    fi
}

echo
echo "PATH TRAVERSAL ATTACKS (should be BLOCKED - HTTP 400)"
echo "--------------------------------------------------------"
test_attack "Parent directory traversal" "/../test" "400"
test_attack "Current directory traversal" "/./test" "400"
test_attack "Double slash" "//test" "400"
test_attack "Path traversal in middle" "/test/../admin" "400"
test_attack "Current dir in middle" "/test/./admin" "400"

echo
echo "URL ENCODED ATTACKS (should be BLOCKED - HTTP 400)"
echo "----------------------------------------------------"
test_attack "URL encoded parent dir" "/%2e%2e/test" "400"
test_attack "URL encoded slash" "/%2f/test" "400"
test_attack "URL encoded backslash" "/%5c/test" "400"
test_attack "Double URL encoded" "/%252e%252e/test" "400"

echo
echo "CONTROL CHARACTER ATTACKS (should be BLOCKED - HTTP 400)"
echo "----------------------------------------------------------"
test_attack "Null byte" "/test%00" "400"
test_attack "Newline character" "/test%0A" "400"
test_attack "Carriage return" "/test%0D" "400"
test_attack "Tab character" "/test%09" "400"

echo
echo "NORMAL REQUESTS (should be ALLOWED)"
echo "-------------------------------------"
test_attack "Root path" "/" "200"
test_attack "Normal path" "/test" "404"
test_attack "Normal nested path" "/api/v1/test" "404"

echo
echo "=================================="
echo "Test completed!"
