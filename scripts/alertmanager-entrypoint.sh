#!/bin/sh
echo "--- DEBUG: Starting Alertmanager Wrapper ---"
echo "Target Variable Length: ${#SLACK_WEBHOOK_URL}"

# Create a temporary config file
cp /etc/alertmanager/alertmanager.yml /tmp/alertmanager.yml

# Use a very simple sed to replace the entire line containing the placeholder
# This avoids issues with nested quotes and minimal sed versions
sed -i "s|api_url:.*|api_url: '${SLACK_WEBHOOK_URL}'|g" /tmp/alertmanager.yml

echo "--- DEBUG: Configuration Processed ---"
# Verify the line was changed (for logs)
grep "api_url" /tmp/alertmanager.yml

# Start Alertmanager
exec /bin/alertmanager "$@" --config.file=/tmp/alertmanager.yml
