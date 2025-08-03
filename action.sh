#!/bin/bash

set_custom_property() {
  local repo_name="$1"
  local owner="$2"
  local token="$3"
  local property_name="$4"
  local property_value="$5"

  # Validate required inputs
  if [ -z "$repo_name" ] || [ -z "$property_name" ] || [ -z "$property_value" ] || [ -z "$owner" ] || [ -z "$token" ]; then
    echo "Error: Missing required parameters"
    echo "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided." >> "$GITHUB_OUTPUT"                        
    echo "result=failure" >> "$GITHUB_OUTPUT"
    return
  fi
  
  echo "Setting '$property_name' custom property to '$property_value' for repository: $owner/$repo_name"

  # Use MOCK_API if set, otherwise default to GitHub API
  local api_base_url="${MOCK_API:-https://api.github.com}"
  local api_url="$api_base_url/repos/$owner/$repo_name/properties/values"
  
  RESPONSE=$(curl -s -o custom_property_response.json -w "%{http_code}" \
    -X PATCH \
    -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    "$api_url" \
    -d "{\"properties\":[{\"property_name\": \"$property_name\", \"value\": \"$property_value\"}]}")
    
  echo "Set Custom Property API Response Code: $RESPONSE"
  cat custom_property_response.json
  
  if [ "$RESPONSE" -ne 204 ]; then
    echo "result=failure" >> $GITHUB_OUTPUT
    echo "error-message=Failed to set '$property_name' custom property to '$property_value': $(jq -r .message custom_property_response.json)" >> $GITHUB_OUTPUT
    echo "Error: Failed to set '$property_name' custom property: $(jq -r .message custom_property_response.json)"
    rm -f custom_property_response.json
    return
  fi
  
  echo "result=success" >> $GITHUB_OUTPUT
  echo "Successfully set '$property_name' custom property to '$property_value' in $owner/$repo_name"
  rm -f custom_property_response.json
}

