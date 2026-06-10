#!/usr/bin/env bash
#
# NDU Project Deployment Guard Script
#
# This script ensures that before any deployment goes to the live domains,
# a confirmation email is sent to the owner (chungu424@gmail.com) and
# explicit approval is received before proceeding.
#
# Usage:
#   ./deploy_with_confirmation.sh [staging|admin|both] [commit-message] [changes-summary]
#
# Environment Variables (required):
#   FIREBASE_PROJECT_ID  - Firebase project ID (default: ndu-d3f60)
#   FIREBASE_REGION      - Firebase functions region (default: us-central1)
#
# The script will:
#   1. Send a confirmation email via Firebase Cloud Function
#   2. Poll for approval (up to 30 minutes)
#   3. Only proceed with deployment if approved
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-ndu-d3f60}"
FIREBASE_REGION="${FIREBASE_REGION:-us-central1}"
FUNCTION_BASE_URL="https://${FIREBASE_REGION}-${FIREBASE_PROJECT_ID}.cloudfunctions.net"
POLL_INTERVAL=15  # seconds
MAX_POLL_TIME=1800  # 30 minutes in seconds

# Arguments
TARGET="${1:-both}"
COMMIT_MESSAGE="${2:-$(git -C /home/z/my-project/Ndu_Project log -1 --pretty=%B 2>/dev/null || echo 'Manual deployment')}"
CHANGES_SUMMARY="${3:-Automated deployment from CI/CD pipeline}"
BRANCH="${GITHUB_REF_NAME:-$(git -C /home/z/my-project/Ndu_Project rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'main')}"
COMMIT_HASH="$(git -C /home/z/my-project/Ndu_Project rev-parse HEAD 2>/dev/null || echo 'unknown')"

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  NDU Project Deployment Guard${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${BLUE}Target:${NC}        ${TARGET}"
echo -e "${BLUE}Branch:${NC}        ${BRANCH}"
echo -e "${BLUE}Commit:${NC}        ${COMMIT_HASH:0:12}"
echo -e "${BLUE}Message:${NC}       ${COMMIT_MESSAGE}"
echo ""

# Determine domains based on target
case "$TARGET" in
  staging)
    DOMAINS='["staging.nduproject.com"]'
    ;;
  admin)
    DOMAINS='["admin.nduproject.com"]'
    ;;
  both)
    DOMAINS='["staging.nduproject.com", "admin.nduproject.com"]'
    ;;
  *)
    echo -e "${RED}Invalid target: ${TARGET}. Use staging, admin, or both.${NC}"
    exit 1
    ;;
esac

echo -e "${YELLOW}Sending confirmation email to owner...${NC}"

# Send the deployment confirmation request
SEND_RESPONSE=$(curl -s -X POST \
  "${FUNCTION_BASE_URL}/sendDeploymentConfirmation" \
  -H "Content-Type: application/json" \
  -d "{
    \"target\": \"${TARGET}\",
    \"commitHash\": \"${COMMIT_HASH}\",
    \"commitMessage\": \"${COMMIT_MESSAGE}\",
    \"branch\": \"${BRANCH}\",
    \"deployedBy\": \"deploy-script\",
    \"domains\": ${DOMAINS},
    \"changesSummary\": \"${CHANGES_SUMMARY}\"
  }" 2>&1)

echo -e "${BLUE}Response:${NC} ${SEND_RESPONSE}"

# Extract request ID and status
REQUEST_ID=$(echo "${SEND_RESPONSE}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('requestId',''))" 2>/dev/null || echo "")
STATUS=$(echo "${SEND_RESPONSE}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null || echo "")

if [ -z "$REQUEST_ID" ]; then
  echo -e "${RED}Failed to send confirmation email. Response:${NC}"
  echo "${SEND_RESPONSE}"
  echo ""
  echo -e "${YELLOW}Do you want to proceed anyway? (y/N)${NC}"
  read -r PROCEED
  if [ "$PROCEED" != "y" ] && [ "$PROCEED" != "Y" ]; then
    echo -e "${RED}Deployment cancelled.${NC}"
    exit 1
  fi
  echo -e "${YELLOW}Proceeding without email confirmation...${NC}"
  # Jump to deployment
  exec ./deploy.sh
fi

# If auto-approved (no email config)
if [ "$STATUS" = "approved" ]; then
  echo -e "${GREEN}Deployment auto-approved (no email config). Proceeding...${NC}"
  exec ./deploy.sh
fi

echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  WAITING FOR OWNER APPROVAL${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "  Request ID: ${CYAN}${REQUEST_ID}${NC}"
echo -e "  Confirmation email sent to: ${CYAN}chungu424@gmail.com${NC}"
echo -e "  Polling every ${POLL_INTERVAL}s (max ${MAX_POLL_TIME}s = 30 min)"
echo ""
echo -e "  You can also check status manually:"
echo -e "  ${CYAN}${FUNCTION_BASE_URL}/checkDeploymentStatus?requestId=${REQUEST_ID}${NC}"
echo ""

# Poll for approval
ELAPSED=0
while [ $ELAPSED -lt $MAX_POLL_TIME ]; do
  sleep $POLL_INTERVAL
  ELAPSED=$((ELAPSED + POLL_INTERVAL))

  CHECK_RESPONSE=$(curl -s "${FUNCTION_BASE_URL}/checkDeploymentStatus?requestId=${REQUEST_ID}" 2>&1)
  CURRENT_STATUS=$(echo "${CHECK_RESPONSE}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null || echo "error")

  REMAINING=$(( (MAX_POLL_TIME - ELAPSED) / 60 ))
  echo -e "  [$(date +%H:%M:%S)] Status: ${CYAN}${CURRENT_STATUS}${NC} (${REMAINING} min remaining)"

  case "$CURRENT_STATUS" in
    approved)
      echo ""
      echo -e "${GREEN}========================================${NC}"
      echo -e "${GREEN}  DEPLOYMENT APPROVED${NC}"
      echo -e "${GREEN}========================================${NC}"
      echo ""
      echo -e "${GREEN}Proceeding with deployment...${NC}"
      exec ./deploy.sh
      ;;
    rejected)
      echo ""
      echo -e "${RED}========================================${NC}"
      echo -e "${RED}  DEPLOYMENT REJECTED${NC}"
      echo -e "${RED}========================================${NC}"
      echo ""
      echo -e "${RED}The owner has rejected this deployment.${NC}"
      exit 1
      ;;
    expired)
      echo ""
      echo -e "${RED}========================================${NC}"
      echo -e "${RED}  REQUEST EXPIRED${NC}"
      echo -e "${RED}========================================${NC}"
      echo ""
      echo -e "${RED}The deployment request has expired (30 min window).${NC}"
      echo -e "${YELLOW}Please initiate a new deployment.${NC}"
      exit 1
      ;;
    pending)
      # Still waiting
      ;;
    *)
      echo -e "${YELLOW}  Warning: Unexpected status '${CURRENT_STATUS}'. Retrying...${NC}"
      ;;
  esac
done

echo ""
echo -e "${RED}========================================${NC}"
echo -e "${RED}  TIMEOUT${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo -e "${RED}No approval received within 30 minutes.${NC}"
echo -e "${YELLOW}The deployment request has expired.${NC}"
exit 1
