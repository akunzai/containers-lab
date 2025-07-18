#!/usr/bin/env bash
set -euo pipefail
# Generate JSONL log files script
# Usage: ./generate_logs.sh [output_file] [log_count]

# Default values
OUTPUT_FILE="${1:-logs/generated.jsonl}"
LOG_COUNT="${2:-100}"

# Log levels
LEVELS=("DEBUG" "INFO" "WARN" "ERROR" "FATAL")
SEVERITIES=("Debug" "Information" "Warning" "Error" "Critical")

# Service names
SERVICES=("UserService" "AuthService" "PaymentService" "OrderService" "NotificationService" "ProductService")

# Log message templates
MESSAGES=(
    "User {user_id} logged in successfully"
    "Authentication failed for user {user_id}"
    "Payment processed for order {order_id}"
    "Order {order_id} created successfully"
    "Email notification sent to {email}"
    "Product {product_id} updated"
    "Database connection established"
    "Cache miss for key {cache_key}"
    "API request processed in {duration}ms"
    "System health check passed"
    "Configuration reloaded"
    "Batch job completed with {count} items"
    "Rate limit exceeded for IP {ip_address}"
    "File upload completed: {filename}"
    "Scheduled task executed"
)

# Error messages
ERROR_MESSAGES=(
    "Database connection failed"
    "External API timeout"
    "Invalid request payload"
    "Authentication token expired"
    "Insufficient permissions"
    "Resource not found"
    "Service temporarily unavailable"
    "Memory allocation failed"
    "Disk space running low"
    "Network connectivity issues"
)

# Generate random user ID
generate_user_id() {
    echo "user_$(($RANDOM % 1000 + 1))"
}

# Generate random order ID
generate_order_id() {
    echo "order_$(date +%s)_$(($RANDOM % 1000))"
}

# Generate random product ID
generate_product_id() {
    echo "prod_$(($RANDOM % 500 + 1))"
}

# Generate random timestamp (within last 7 days)
generate_timestamp() {
    local now=$(date +%s)
    local random_offset=$(($RANDOM % 604800))  # 7 days in seconds
    local timestamp=$((now - random_offset))
    echo "${timestamp}000000000"  # Convert to nanoseconds
}

# Generate random IP
generate_ip() {
    echo "$(($RANDOM % 256)).$(($RANDOM % 256)).$(($RANDOM % 256)).$(($RANDOM % 256))"
}

# Generate random email
generate_email() {
    local names=("john" "jane" "bob" "alice" "charlie" "diana" "eve" "frank")
    local domains=("example.com" "test.org" "demo.net" "sample.io")
    local name=${names[$RANDOM % ${#names[@]}]}
    local domain=${domains[$RANDOM % ${#domains[@]}]}
    echo "${name}@${domain}"
}

# Generate random filename
generate_filename() {
    local files=("report.pdf" "image.jpg" "data.csv" "config.json" "log.txt")
    echo ${files[$RANDOM % ${#files[@]}]}
}

# Replace variables in message
replace_variables() {
    local message="$1"
    message="${message//\{user_id\}/$(generate_user_id)}"
    message="${message//\{order_id\}/$(generate_order_id)}"
    message="${message//\{product_id\}/$(generate_product_id)}"
    message="${message//\{email\}/$(generate_email)}"
    message="${message//\{ip_address\}/$(generate_ip)}"
    message="${message//\{filename\}/$(generate_filename)}"
    message="${message//\{duration\}/$(($RANDOM % 1000 + 10))}"
    message="${message//\{count\}/$(($RANDOM % 10000 + 1))}"
    message="${message//\{cache_key\}/cache_$(($RANDOM % 1000))}"
    echo "$message"
}

# Generate single log entry
generate_log_entry() {
    local level_index=$(($RANDOM % ${#LEVELS[@]}))
    local level=${LEVELS[$level_index]}
    local severity=${SEVERITIES[$level_index]}
    local service=${SERVICES[$RANDOM % ${#SERVICES[@]}]}
    local timestamp=$(generate_timestamp)
    
    local message
    if [[ "$level" == "ERROR" || "$level" == "FATAL" ]]; then
        message=${ERROR_MESSAGES[$RANDOM % ${#ERROR_MESSAGES[@]}]}
    else
        message=${MESSAGES[$RANDOM % ${#MESSAGES[@]}]}
    fi
    
    message=$(replace_variables "$message")
    
    # Generate JSONL format - one JSON per line
    echo "{\"line\":\"{\\\"body\\\":\\\"$message\\\",\\\"severity\\\":\\\"$severity\\\",\\\"level\\\":\\\"$level\\\",\\\"service\\\":\\\"$service\\\",\\\"timestamp\\\":\\\"$(date -r $((timestamp/1000000000)) -u +%Y-%m-%dT%H:%M:%S.%3NZ)\\\"}\",\"timestamp\":\"$timestamp\",\"fields\":{\"body\":\"$message\",\"severity\":\"$severity\",\"level\":\"$level\",\"service_name\":\"$service\",\"job\":\"$service\",\"detected_level\":\"$level\"}}"
}

# Main function
main() {
    echo "Generating $LOG_COUNT log entries to $OUTPUT_FILE"
    
    # Ensure output directory exists
    mkdir -p "$(dirname "$OUTPUT_FILE")"
    
    # Clear or create output file
    > "$OUTPUT_FILE"
    
    # Generate log entries
    for ((i=1; i<=LOG_COUNT; i++)); do
        generate_log_entry >> "$OUTPUT_FILE"
        if (( i % 10 == 0 )); then
            echo "Generated $i/$LOG_COUNT logs..."
        fi
    done
    
    echo "✅ Done! Generated $LOG_COUNT logs to $OUTPUT_FILE"
    echo "File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    echo "Usage: Copy this file to logs/ directory, Alloy will parse it automatically"
}

# Execute main function
main "$@"