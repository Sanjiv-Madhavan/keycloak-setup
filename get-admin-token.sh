#!/bin/bash
KEYCLOAK_URL="http://keycloak.local"
REALM="master"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin_password" # Replace with your admin password

response=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$ADMIN_USER" \
    -d "password=$ADMIN_PASSWORD" \
    -d "grant_type=password" \
    -d "client_id=admin-cli")

echo $(echo $response | jq -r .access_token)
