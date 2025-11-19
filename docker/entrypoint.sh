#!/bin/bash
set -e

# Copy the config template to a writable location
cp /etc/parsedmarc/parsedmarc.ini /tmp/parsedmarc.ini

# Inject IMAP password from environment variable
if [ -n "$IMAP_PASSWORD" ]; then
  awk -v pwd="$IMAP_PASSWORD" '/^\[imap\]/ {print; print "password = " pwd; next} 1' /tmp/parsedmarc.ini > /tmp/parsedmarc.ini.tmp
  mv /tmp/parsedmarc.ini.tmp /tmp/parsedmarc.ini
fi

# Inject SMTP password from environment variable
if [ -n "$SMTP_PASSWORD" ]; then
  awk -v pwd="$SMTP_PASSWORD" '/^\[smtp\]/ {print; print "password = " pwd; next} 1' /tmp/parsedmarc.ini > /tmp/parsedmarc.ini.tmp
  mv /tmp/parsedmarc.ini.tmp /tmp/parsedmarc.ini
fi

# Inject Splunk token from environment variable
if [ -n "$SPLUNK_TOKEN" ]; then
  awk -v token="$SPLUNK_TOKEN" '/^\[splunk_hec\]/ {print; print "token = " token; next} 1' /tmp/parsedmarc.ini > /tmp/parsedmarc.ini.tmp
  mv /tmp/parsedmarc.ini.tmp /tmp/parsedmarc.ini
fi

# Execute parsedmarc with the modified config
exec parsedmarc -c /tmp/parsedmarc.ini "$@"
