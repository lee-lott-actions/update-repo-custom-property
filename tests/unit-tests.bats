#!/usr/bin/env bats

# Load the Bash script (source the action's script)
load ../action.sh

# Mock the curl command to simulate API responses
mock_curl() {
  local http_code=$1
  local response_file=$2
  echo "$http_code"
  cat "$response_file" > response.json
}

# Mock jq command to extract message from JSON
mock_jq() {
  local key=$1
  local file=$2
  cat "$file" | grep "$key" | cut -d'"' -f4
}

# Setup function to run before each test
setup() {
  export GITHUB_OUTPUT=$(mktemp)
}

# Teardown function to clean up after each test
teardown() {
  rm -f response.json "$GITHUB_OUTPUT" mock_response.json
}

@test "set_custom_property succeeds with HTTP 204" {
  echo '{"message": "Property set"}' > mock_response.json
  curl() { mock_curl "204" mock_response.json; }
  export -f curl

  run set_custom_property "test-repo" "test-owner" "fake-token" "env" "production"

  [ "$status" -eq 0 ]
  [ "$(cat "$GITHUB_OUTPUT")" == "result=success" ]
}

@test "set_custom_property fails with HTTP 403" {
  echo '{"message": "Forbidden"}' > mock_response.json
  curl() { mock_curl "403" mock_response.json; }
  jq() { mock_jq ".message" "mock_response.json"; }
  export -f curl
  export -f jq

  run set_custom_property "test-repo" "test-owner" "fake-token" "env" "production"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Failed to set 'env' custom property to 'production': Forbidden" ]
}

@test "set_custom_property fails with empty repo_name" {
  run set_custom_property "" "test-owner" "fake-token" "env" "production"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided." ]
}

@test "set_custom_property fails with empty owner" {
  run set_custom_property "test-repo" "" "fake-token" "env" "production"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided." ]
}

@test "set_custom_property fails with empty token" {
  run set_custom_property "test-repo" "test-owner" "" "env" "production"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided." ]
}

@test "set_custom_property fails with empty property_name" {
  run set_custom_property "test-repo" "test-owner" "fake-token" "" "production"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided." ]
}

@test "set_custom_property fails with empty property_value" {
  run set_custom_property "test-repo" "test-owner" "fake-token" "env" ""

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: repo_name, property_name, property_value, owner, and token must be provided." ]
}
