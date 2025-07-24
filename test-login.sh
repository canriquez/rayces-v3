#!/bin/bash

echo "Testing login endpoint..."
echo

# Test login
RESPONSE=$(curl -s -X POST http://localhost:4000/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "X-Organization-Subdomain: rayces" \
  -d '{"user":{"email":"admin@rayces.com","password":"password123"}}')

echo "Login response:"
echo "$RESPONSE" | jq '.'

# Extract token
TOKEN=$(echo "$RESPONSE" | jq -r '.token')

if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
  echo
  echo "Login successful! Token extracted."
  echo
  echo "Testing protected /api/v1/users endpoint..."
  
  curl -s -X GET http://localhost:4000/api/v1/users \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-Organization-Subdomain: rayces" \
    -H "Accept: application/json" | jq '.'
else
  echo "Login failed - no token received"
fi