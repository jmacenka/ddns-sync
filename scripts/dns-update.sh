#!/bin/bash

# Variables
CLOUDFLARE_API_KEY="$1"
DOMAIN="$2"
SUBDOMAINS="$3"
LOG_FILE="/var/log/dns-sync.log"

log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

# Check if Cloudflare API key and Domain are provided
if [[ -z "$CLOUDFLARE_API_KEY" || -z "$DOMAIN" ]]; then
  log "Error: Missing Cloudflare API key or Domain."
  echo "Usage: $0 <Cloudflare-API-key> <Domain> [sub1,sub2,...]"
  exit 1
fi

# Retrieve public IP addresses
IPV4=$(curl -s https://ipv4.icanhazip.com)
IPV6=$(curl -s https://ipv6.icanhazip.com)

log "Retrieved IPv4: $IPV4"
log "Retrieved IPv6: $IPV6"

# Function to update Cloudflare DNS
update_dns() {
  local RECORD_NAME="$1"
  local TYPE="$2"
  local IP="$3"

  # Fetch the zone id of the domain
  ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
    -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  # Log error if Zone ID is not retrieved
  if [[ "$ZONE_ID" == "null" ]]; then
    log "Error: Unable to fetch Zone ID for $DOMAIN"
    return
  fi

  # Fetch the record id
  RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=$TYPE&name=$RECORD_NAME" \
    -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  # Log error if Record ID is not retrieved
  if [[ "$RECORD_ID" == "null" ]]; then
    log "Error: Unable to fetch Record ID for $RECORD_NAME"
    return
  fi

  # Update the DNS record
  RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"$TYPE\",\"name\":\"$RECORD_NAME\",\"content\":\"$IP\"}")

  # Log the response
  SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
  ERRORS=$(echo "$RESPONSE" | jq -r '.errors')
  log "Updated $RECORD_NAME ($TYPE) to IP: $IP. Success: $SUCCESS. Errors: $ERRORS"
}

# Update the root domain
if [[ ! -z "$IPV4" ]]; then
  update_dns "$DOMAIN" "A" "$IPV4"
fi

if [[ ! -z "$IPV6" ]]; then
  update_dns "$DOMAIN" "AAAA" "$IPV6"
fi

# Update subdomains if provided
IFS=',' read -ra ADDR <<< "$SUBDOMAINS"
for i in "${ADDR[@]}"; do
  SUB="$i.$DOMAIN"
  if [[ ! -z "$IPV4" ]]; then
    update_dns "$SUB" "A" "$IPV4"
  fi

  if [[ ! -z "$IPV6" ]]; then
    update_dns "$SUB" "AAAA" "$IPV6"
  fi
done

log "Script execution completed."