#!/bin/bash

# 測試 nginx 對控制字符攻擊的防護
# 基於 HTTP Request Smuggling / Control Character Injection 攻擊

BASE_URL="https://www.dev.local:8443"
FAIL_COUNT=0
PASS_COUNT=0

echo "========================================"
echo "Testing nginx Control Character Defense"
echo "========================================"
echo ""

# 輔助函數：執行測試
test_request() {
    local test_name="$1"
    local path="$2"
    local should_block="$3"

    echo "Test: $test_name"
    echo "Path: $path"

    # 使用 --path-as-is 防止 curl 正規化 URL
    response=$(curl -sk --path-as-is -o /dev/null -w "%{http_code}" "${BASE_URL}${path}" 2>/dev/null)

    if [ "$should_block" = "yes" ]; then
        if [ "$response" = "400" ]; then
            echo "✓ PASS: Blocked with HTTP 400"
            ((PASS_COUNT++))
        else
            echo "✗ FAIL: Expected 400, got HTTP $response"
            ((FAIL_COUNT++))
        fi
    else
        if [ "$response" != "400" ]; then
            echo "✓ PASS: Allowed with HTTP $response"
            ((PASS_COUNT++))
        else
            echo "✗ FAIL: Should allow but got HTTP 400"
            ((FAIL_COUNT++))
        fi
    fi
    echo ""
}

echo "=== Test 1: TAB character (0x09) - URL encoded ==="
test_request "Basic TAB injection" "/secret%09HTTP/1.1/../../public" "yes"

echo "=== Test 2: Double-encoded TAB ==="
test_request "Double-encoded TAB" "/secret%2509HTTP/1.1/../../public" "yes"

echo "=== Test 3: Your specific example ==="
test_request "Specific attack example" "/mpay/admin/login;jsessionid=E2F74319D1DF611C2377460FEB768C71%09HTTP/1.1/../../" "yes"

echo "=== Test 4: CR (Carriage Return) ==="
test_request "CR character" "/secret%0dHTTP/1.1/../../public" "yes"

echo "=== Test 5: LF (Line Feed) ==="
test_request "LF character" "/secret%0aHTTP/1.1/../../public" "yes"

echo "=== Test 6: NULL byte ==="
test_request "NULL byte" "/secret%00HTTP/1.1/../../public" "yes"

echo "=== Test 7: Vertical Tab (0x0b) ==="
test_request "Vertical Tab" "/secret%0bHTTP/1.1/../../public" "yes"

echo "=== Test 8: Form Feed (0x0c) ==="
test_request "Form Feed" "/secret%0cHTTP/1.1/../../public" "yes"

echo "=== Test 9: Multiple control chars ==="
test_request "Multiple control chars" "/secret%09%0d%0aHTTP/1.1/" "yes"

echo "=== Test 10: Control char in query string ==="
test_request "TAB in query string" "/page?param=value%09&next=data" "yes"

echo "=== Test 11: DEL character (0x7f) ==="
test_request "DEL character" "/secret%7fHTTP/1.1/../../public" "yes"

echo "=== Test 12: Other control chars (0x10-0x1f) ==="
test_request "Control char 0x10" "/secret%10HTTP/1.1/" "yes"
test_request "Control char 0x1f" "/secret%1fHTTP/1.1/" "yes"

echo "=== Test 13: Baseline - Normal request (should allow) ==="
test_request "Normal request" "/" "no"

echo "=== Test 14: Normal path with query (should allow) ==="
test_request "Normal with query" "/page?param=value" "no"

echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
echo "Total Passed: $PASS_COUNT"
echo "Total Failed: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✓ All tests passed! nginx is properly protected."
    exit 0
else
    echo "✗ Some tests failed. Review the configuration."
    exit 1
fi
