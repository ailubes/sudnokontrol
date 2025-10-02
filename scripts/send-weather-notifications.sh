#!/bin/bash

# Weather Notification Automation Script
# This script sends weather notifications to users based on their regional access

# Configuration
API_URL="${API_URL:-https://api-dev.sudnokontrol.online/api/notifications/weather/send}"
SEVERITY_THRESHOLD="${SEVERITY_THRESHOLD:-medium}"
LOG_FILE="/var/log/weather-notifications.log"

# Admin credentials - get a service account token
# You should create a dedicated service account for automated tasks
ADMIN_PHONE="+380999999999"
ADMIN_PASSWORD="${WEATHER_CRON_PASSWORD}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting weather notification check..." >> "$LOG_FILE"

# Login to get token
TOKEN_RESPONSE=$(curl -s -X POST "${API_URL%/notifications/weather/send}/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"phone\":\"$ADMIN_PHONE\",\"password\":\"$ADMIN_PASSWORD\"}")

TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to get authentication token" >> "$LOG_FILE"
  echo "$TOKEN_RESPONSE" >> "$LOG_FILE"
  exit 1
fi

# Send weather notifications
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"severityThreshold\":\"$SEVERITY_THRESHOLD\"}")

# Log response
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Response: $RESPONSE" >> "$LOG_FILE"

# Check if successful
if echo "$RESPONSE" | grep -q '"message"'; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Weather notifications sent successfully" >> "$LOG_FILE"
  exit 0
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to send weather notifications" >> "$LOG_FILE"
  exit 1
fi
