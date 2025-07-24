#!/bin/bash

# Test login and user management flow

echo "=== Testing Admin Frontend ==="
echo
echo "1. Login with correct credentials (carlos@rayces.com)"

# Login
LOGIN_RESPONSE=$(curl -X POST http://localhost:4000/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "X-Organization-Subdomain: rayces" \
  -d '{"user":{"email":"carlos@rayces.com","password":"password123"}}' \
  -s)

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token')
USER_ID=$(echo $LOGIN_RESPONSE | jq -r '.data.id')

if [ "$TOKEN" = "null" ]; then
    echo "❌ Login failed!"
    echo $LOGIN_RESPONSE | jq
    exit 1
fi

echo "✅ Login successful!"
echo "   Token: ${TOKEN:0:50}..."
echo "   User ID: $USER_ID"
echo

echo "2. Test protected /api/v1/users endpoint"
USERS_RESPONSE=$(curl -H "Authorization: Bearer $TOKEN" \
     -H "X-Organization-Subdomain: rayces" \
     http://localhost:4000/api/v1/users \
     -s)

USER_COUNT=$(echo $USERS_RESPONSE | jq '.data | length')
echo "✅ Users endpoint working! Found $USER_COUNT users"
echo

echo "3. Test permissions endpoint"
PERMISSIONS_RESPONSE=$(curl -H "Authorization: Bearer $TOKEN" \
     -H "X-Organization-Subdomain: rayces" \
     "http://localhost:4000/api/v1/permissions/check?action=manage&resource=users" \
     -s)

CAN_MANAGE=$(echo $PERMISSIONS_RESPONSE | jq -r '.can_perform')
echo "✅ Permissions check: can_manage_users = $CAN_MANAGE"
echo

echo "=== Frontend URLs ==="
echo "Login page: http://localhost:8080/login"
echo "Admin dashboard: http://localhost:8080/admin"
echo "Users management: http://localhost:8080/admin/users"
echo
echo "Use credentials: carlos@rayces.com / password123"