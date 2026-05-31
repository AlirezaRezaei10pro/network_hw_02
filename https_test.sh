#!/bin/bash

# https_test.sh - HTTPS Testing Script
# Tests SSL/TLS certificate and connection details for a given HTTPS URL

TARGET_URL="${1:-https://www.google.com}"
HOSTNAME=$(echo "$TARGET_URL" | sed 's|https://||' | sed 's|/.*||')
OUTPUT_FILE="https_test_report.txt"

echo "============================================" | tee "$OUTPUT_FILE"
echo "  HTTPS Test Report" | tee -a "$OUTPUT_FILE"
echo "  Target: $TARGET_URL" | tee -a "$OUTPUT_FILE"
echo "  Date: $(date)" | tee -a "$OUTPUT_FILE"
echo "============================================" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 1. Send HTTPS request
echo "--- [1] HTTPS Request ---" | tee -a "$OUTPUT_FILE"
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 "$TARGET_URL")
if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 400 ]; then
    echo "✔  HTTP Status: $HTTP_STATUS (Success)" | tee -a "$OUTPUT_FILE"
else
    echo "✘  HTTP Status: $HTTP_STATUS (Failed or Redirect)" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 2. Check SSL certificate chain
echo "--- [2] SSL Certificate Chain ---" | tee -a "$OUTPUT_FILE"
CERT_CHAIN=$(echo | openssl s_client -connect "$HOSTNAME:443" -showcerts 2>/dev/null)
CERT_COUNT=$(echo "$CERT_CHAIN" | grep -c "BEGIN CERTIFICATE")
echo "Certificate chain depth: $CERT_COUNT certificate(s)" | tee -a "$OUTPUT_FILE"

# Extract and display each certificate subject/issuer
echo "$CERT_CHAIN" | awk '
/BEGIN CERTIFICATE/{cert=""; in_cert=1}
in_cert{cert=cert"\n"$0}
/END CERTIFICATE/{
    print cert | "openssl x509 -noout -subject -issuer 2>/dev/null"
    in_cert=0
    print "---"
}' 2>/dev/null | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 3. Show TLS version in use
echo "--- [3] TLS Version ---" | tee -a "$OUTPUT_FILE"
TLS_INFO=$(echo | openssl s_client -connect "$HOSTNAME:443" 2>/dev/null | grep "Protocol\|Cipher")
echo "$TLS_INFO" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 4. Check certificate expiry date
echo "--- [4] Certificate Expiry ---" | tee -a "$OUTPUT_FILE"
EXPIRY=$(echo | openssl s_client -connect "$HOSTNAME:443" 2>/dev/null \
    | openssl x509 -noout -dates 2>/dev/null)

NOT_BEFORE=$(echo "$EXPIRY" | grep "notBefore" | cut -d= -f2)
NOT_AFTER=$(echo "$EXPIRY" | grep "notAfter" | cut -d= -f2)

echo "Valid From:    $NOT_BEFORE" | tee -a "$OUTPUT_FILE"
echo "Valid Until:   $NOT_AFTER" | tee -a "$OUTPUT_FILE"

# Calculate days until expiry
EXPIRY_EPOCH=$(date -d "$NOT_AFTER" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$NOT_AFTER" +%s 2>/dev/null)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

if [ "$DAYS_LEFT" -gt 30 ]; then
    echo "✔  Certificate is valid for $DAYS_LEFT more days." | tee -a "$OUTPUT_FILE"
elif [ "$DAYS_LEFT" -gt 0 ]; then
    echo "⚠  WARNING: Certificate expires in $DAYS_LEFT days!" | tee -a "$OUTPUT_FILE"
else
    echo "✘  CRITICAL: Certificate has EXPIRED!" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

echo "============================================" | tee -a "$OUTPUT_FILE"
echo "  Report saved to: $OUTPUT_FILE" | tee -a "$OUTPUT_FILE"
echo "============================================" | tee -a "$OUTPUT_FILE"
