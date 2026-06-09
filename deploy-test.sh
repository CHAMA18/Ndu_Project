#!/usr/bin/env bash
#
# NDU Project - Deploy to Test Instance
#
# This script deploys the latest built web app to the testing instance.
# The test instance uses GitHub Pages at:
#   https://chama18.github.io/NDU-Test/
#
# IMPORTANT: Do NOT use a custom domain or CNAME file.
# The site must always be accessible at the GitHub Pages URL above.
#
# Usage:
#   ./deploy-test.sh                    # Deploy current build to test
#   ./deploy-test.sh --build            # Build fresh from source, then deploy
#   ./deploy-test.sh --build --confirm  # Build, send email confirmation, then deploy
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
SOURCE_DIR="/home/z/my-project/Ndu_Project"
BUILD_DIR="$SOURCE_DIR/build/web"
TEST_REPO_DIR="/home/z/my-project/NDU-Test"
FLUTTER_PATH="/home/z/flutter/bin/flutter"
BASE_HREF="/NDU-Test/"
DEPLOY_MSG="${2:-Update test instance with latest build}"

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  NDU Project - Test Instance Deploy${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Parse arguments
DO_BUILD=false
DO_CONFIRM=false
for arg in "$@"; do
  case $arg in
    --build)   DO_BUILD=true ;;
    --confirm) DO_CONFIRM=true ;;
    --help)
      echo "Usage: ./deploy-test.sh [--build] [--confirm]"
      echo ""
      echo "  --build    Rebuild from source before deploying"
      echo "  --confirm  Send email confirmation before deploying"
      echo "  --help     Show this help"
      exit 0
      ;;
  esac
done

# Step 1: Build if requested
if [ "$DO_BUILD" = true ]; then
  echo -e "${YELLOW}Building Flutter web app...${NC}"

  if [ ! -f "$FLUTTER_PATH" ]; then
    echo -e "${RED}Flutter SDK not found at $FLUTTER_PATH${NC}"
    echo -e "${YELLOW}Installing Flutter SDK...${NC}"
    git clone https://github.com/flutter/flutter.git -b stable /home/z/flutter --depth 1
    export PATH="/home/z/flutter/bin:$PATH"
    flutter --version
  fi

  export PATH="/home/z/flutter/bin:$PATH"
  cd "$SOURCE_DIR"

  echo -e "${BLUE}Running: flutter build web --release --no-tree-shake-icons --base-href "$BASE_HREF"${NC}"
  /home/z/flutter/bin/flutter build web --release --no-tree-shake-icons --base-href "$BASE_HREF"

  # Patch canvaskit config
  if grep -q "canvasKitBaseUrl" "$BUILD_DIR/flutter_bootstrap.js"; then
    echo -e "${GREEN}canvasKitBaseUrl already configured${NC}"
  else
    echo -e "${YELLOW}Patching flutter_bootstrap.js for local canvaskit...${NC}"
    sed -i 's/_flutter.loader.load({/_flutter.loader.load({\n  config: {\n    canvasKitBaseUrl: "canvaskit\/"\n  },/' "$BUILD_DIR/flutter_bootstrap.js"
  fi

  echo -e "${GREEN}Build complete!${NC}"
  echo ""
fi

# Step 2: Check build exists
if [ ! -f "$BUILD_DIR/index.html" ]; then
  echo -e "${RED}No build found at $BUILD_DIR${NC}"
  echo -e "${YELLOW}Run with --build flag to build first: ./deploy-test.sh --build${NC}"
  exit 1
fi

# Step 3: Email confirmation if requested
if [ "$DO_CONFIRM" = true ]; then
  echo -e "${YELLOW}Sending deployment confirmation email...${NC}"
  cd "$SOURCE_DIR"
  RESULT=$(node send-deployment-email.js --target test --message "$DEPLOY_MSG" --summary "Test instance deployment" 2>&1)
  echo "$RESULT"

  RESULT_JSON=$(echo "$RESULT" | grep "RESULT:" | sed 's/RESULT://')
  REQUEST_ID=$(echo "$RESULT_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('requestId',''))" 2>/dev/null || echo "")

  if [ -n "$REQUEST_ID" ]; then
    echo ""
    echo -e "${YELLOW}Deployment request created: ${CYAN}${REQUEST_ID}${NC}"
    echo -e "${YELLOW}Waiting for approval...${NC}"
    echo -e "${YELLOW}(In manual mode, approve by responding in chat)${NC}"
    echo ""

    # Check approval status
    APPROVAL_FILE="$SOURCE_DIR/.deployment_approval.json"
    ELAPSED=0
    while [ $ELAPSED -lt 1800 ]; do
      sleep 10
      ELAPSED=$((ELAPSED + 10))

      if [ -f "$APPROVAL_FILE" ]; then
        STATUS=$(python3 -c "import json; print(json.load(open('$APPROVAL_FILE')).get('status',''))" 2>/dev/null || echo "")
        case $STATUS in
          approved)
            echo -e "${GREEN}Deployment approved!${NC}"
            break
            ;;
          rejected)
            echo -e "${RED}Deployment rejected.${NC}"
            exit 1
            ;;
        esac
      fi

      REMAINING=$(( (1800 - ELAPSED) / 60 ))
      echo -e "  [$(date +%H:%M:%S)] Status: ${CYAN}${STATUS:-pending}${NC} (${REMAINING} min remaining)"
    done
  fi
fi

# Step 4: Copy files to test repo
echo -e "${YELLOW}Copying build files to test repo...${NC}"

# Make sure the test repo exists and is up to date
if [ ! -d "$TEST_REPO_DIR/.git" ]; then
  echo -e "${YELLOW}Cloning test repo...${NC}"
  git clone https://${GITHUB_TOKEN}@github.com/CHAMA18/NDU-Test.git "$TEST_REPO_DIR"
fi

cd "$TEST_REPO_DIR"
git pull origin main 2>/dev/null || true

# Remove old files (keep .git)
find . -maxdepth 1 ! -name '.' ! -name '.git' ! -name '.gitignore' -exec rm -rf {} +

# Copy new files
cp -r "$BUILD_DIR"/* .

# ============================================================
# CRITICAL: NEVER create a CNAME file in this repo!
# CNAME causes GitHub Pages to use a custom domain, which
# breaks the chama18.github.io/NDU-Test/ URL.
# If a CNAME file was somehow created, remove it.
# ============================================================
if [ -f "CNAME" ]; then
  echo -e "${RED}WARNING: CNAME file found! Removing it to prevent custom domain redirect.${NC}"
  rm -f CNAME
fi

# Ensure .nojekyll exists to prevent Jekyll processing
touch .nojekyll

# Add 404.html for SPA routing (subpath version for /NDU-Test/)
cat > 404.html << 'EOF404'
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>NDU Project Test - Redirecting...</title>
  <script>
    // SPA routing for GitHub Pages subpath (/NDU-Test/)
    var path = window.location.pathname;
    var basePath = '/NDU-Test/';
    if (path.indexOf(basePath) === 0 && path !== basePath) {
      var relativePath = path.substring(basePath.length);
      if (relativePath && relativePath !== '/') {
        window.location.replace(window.location.origin + basePath + window.location.search + '#' + relativePath);
      }
    }
  </script>
</head>
<body>
  <p>Redirecting to NDU Project Test...</p>
</body>
</html>
EOF404

# Patch index.html to add TEST ENVIRONMENT banner and ensure correct base href
echo -e "${YELLOW}Adding TEST ENVIRONMENT banner to index.html...${NC}"

# Inject cache-busting version stamp into index.html (replaces __NDU_VERSION__ placeholders)
NDU_VERSION="$(date +%s)"
echo -e "${BLUE}Injecting cache-bust version: ${NDU_VERSION}${NC}"
sed -i "s/__NDU_VERSION__/${NDU_VERSION}/g" index.html

# Ensure base href is correct for GitHub Pages subpath
sed -i "s|<base href=\"[^\"]*\">|<base href=\"/NDU-Test/\">|g" index.html

# Update title
sed -i 's|<title>NDU Project</title>|<title>NDU Project - TEST ENVIRONMENT</title>|g' index.html

# Add TEST ENVIRONMENT banner CSS and banner element if not already present
if ! grep -q "test-environment-banner" index.html; then
  # Add banner CSS before </style>
  sed -i 's|</style>|#test-environment-banner{position:fixed;top:0;left:0;right:0;z-index:999999;background:linear-gradient(135deg,#d97706,#dc2626);color:white;text-align:center;padding:8px 16px;font-size:13px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;box-shadow:0 2px 12px rgba(217,119,6,0.5);pointer-events:none;user-select:none}#test-environment-banner::after{content:"  TEST ENVIRONMENT - NOT FOR PRODUCTION USE"}\n</style>|' index.html

  # Add banner div after <body>
  sed -i 's|<body>|<body>\n  <div id="test-environment-banner"></div>|' index.html

  # Add persistent banner script before </body>
  sed -i 's|</body>|<script>(function(){var b=document.getElementById("test-environment-banner");var o=new MutationObserver(function(){if(!document.getElementById("test-environment-banner")){var n=document.createElement("div");n.id="test-environment-banner";n.style.cssText="position:fixed;top:0;left:0;right:0;z-index:999999;background:linear-gradient(135deg,#d97706,#dc2626);color:white;text-align:center;padding:8px 16px;font-size:13px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;box-shadow:0 2px 12px rgba(217,119,6,0.5);pointer-events:none;user-select:none;";n.textContent="";document.body.insertBefore(n,document.body.firstChild)}});o.observe(document.body,{childList:true,subtree:true})})();</script>\n</body>|' index.html
fi

echo -e "${GREEN}Files copied and patched successfully${NC}"

# Step 5: Commit and push
echo -e "${YELLOW}Committing and pushing to test repo...${NC}"
git add -A
git commit --author="CHAMA18 <chungu424@gmail.com>" -m "Update test instance: $(date '+%Y-%m-%d %H:%M')" 2>/dev/null || echo "No changes to commit"
git push origin main 2>&1

# ============================================================
# POST-DEPLOY VERIFICATION
# Ensure no CNAME file exists and no custom domain is set
# ============================================================
echo ""
echo -e "${YELLOW}Running post-deploy verification...${NC}"

# Verify no CNAME file in the repo
if [ -f "CNAME" ]; then
  echo -e "${RED}ERROR: CNAME file still exists after deploy! Removing and forcing push.${NC}"
  rm -f CNAME
  git add -A
  git commit --author="CHAMA18 <chungu424@gmail.com>" -m "Emergency: Remove CNAME file" 2>/dev/null || true
  git push origin main 2>&1
fi

# Verify GitHub Pages has no custom domain via API
PAGES_INFO=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/CHAMA18/NDU-Test/pages 2>/dev/null || echo "")
if echo "$PAGES_INFO" | grep -q '"cname"'; then
  CNAME_VALUE=$(echo "$PAGES_INFO" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cname',''))" 2>/dev/null || echo "unknown")
  if [ -n "$CNAME_VALUE" ] && [ "$CNAME_VALUE" != "None" ] && [ "$CNAME_VALUE" != "null" ]; then
    echo -e "${RED}WARNING: Custom domain is set to '$CNAME_VALUE'. Removing it via API...${NC}"
    # Remove custom domain via API by updating Pages with empty cname
    curl -s -X PUT -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3+json" \
      https://api.github.com/repos/CHAMA18/NDU-Test/pages \
      -d '{"cname":null}' 2>/dev/null || true
  else
    echo -e "${GREEN}Verified: No custom domain set on GitHub Pages${NC}"
  fi
else
  echo -e "${GREEN}Verified: GitHub Pages configuration OK${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  TEST INSTANCE DEPLOYED!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "  URL: ${CYAN}https://chama18.github.io/NDU-Test/${NC}"
echo -e "  Repo: ${CYAN}https://github.com/CHAMA18/NDU-Test${NC}"
echo ""
echo -e "  Note: GitHub Pages may take 1-2 minutes to update."
echo ""
