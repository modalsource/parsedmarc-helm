#!/bin/bash
# Test script for entrypoint.sh

echo "Testing entrypoint.sh..."

# Create a mock config file
mkdir -p /tmp/test-parsedmarc
cat > /tmp/test-parsedmarc/parsedmarc.ini << 'INIEOF'
[general]
save_aggregate = True

[imap]
host = imap.example.com
port = 993
user = test@example.com

[smtp]
host = smtp.example.com
port = 587

[splunk_hec]
url = https://splunk.example.com
INIEOF

# Set environment variables
export IMAP_PASSWORD="test-imap-pass"
export SMTP_PASSWORD="test-smtp-pass"
export SPLUNK_TOKEN="test-splunk-token"

# Run the injection logic
cp /tmp/test-parsedmarc/parsedmarc.ini /tmp/parsedmarc.ini

if [ -n "$IMAP_PASSWORD" ]; then
  awk -v pwd="$IMAP_PASSWORD" '/^\[imap\]/ {print; print "password = " pwd; next} 1' /tmp/parsedmarc.ini > /tmp/parsedmarc.ini.tmp
  mv /tmp/parsedmarc.ini.tmp /tmp/parsedmarc.ini
fi

if [ -n "$SMTP_PASSWORD" ]; then
  awk -v pwd="$SMTP_PASSWORD" '/^\[smtp\]/ {print; print "password = " pwd; next} 1' /tmp/parsedmarc.ini > /tmp/parsedmarc.ini.tmp
  mv /tmp/parsedmarc.ini.tmp /tmp/parsedmarc.ini
fi

if [ -n "$SPLUNK_TOKEN" ]; then
  awk -v token="$SPLUNK_TOKEN" '/^\[splunk_hec\]/ {print; print "token = " token; next} 1' /tmp/parsedmarc.ini > /tmp/parsedmarc.ini.tmp
  mv /tmp/parsedmarc.ini.tmp /tmp/parsedmarc.ini
fi

echo "Modified config:"
cat /tmp/parsedmarc.ini

echo ""
echo "Verification:"
grep "password = test-imap-pass" /tmp/parsedmarc.ini && echo "✓ IMAP password injected"
grep "password = test-smtp-pass" /tmp/parsedmarc.ini && echo "✓ SMTP password injected"
grep "token = test-splunk-token" /tmp/parsedmarc.ini && echo "✓ Splunk token injected"

rm -rf /tmp/test-parsedmarc /tmp/parsedmarc.ini
