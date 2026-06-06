#!/usr/bin/env bash
#
# NDU Project - Deploy to Root GitHub Pages (chama18.github.io)
#
# This script deploys the latest built web app to the root GitHub Pages site.
# The site is accessible at:
#   https://chama18.github.io/
#   https://chama18.github.io/#/dashboard
#
# IMPORTANT: Do NOT use a custom domain or CNAME file.
#
# Usage:
#   ./deploy-root.sh                    # Deploy current build to root
#   ./deploy-root.sh --build            # Build fresh from source, then deploy
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SOURCE_DIR="/home/z/my-project/Ndu_Project"
BUILD_DIR="$SOURCE_DIR/build/web"
ROOT_REPO_DIR="/home/z/my-project/chama18.github.io"
FLUTTER_PATH="/home/z/flutter/bin/flutter"
BASE_HREF="/"

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  NDU Project - Root Site Deploy${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Parse arguments
DO_BUILD=false
for arg in "$@"; do
  case $arg in
    --build)   DO_BUILD=true ;;
    --help)
      echo "Usage: ./deploy-root.sh [--build]"
      echo ""
      echo "  --build    Rebuild from source before deploying"
      echo "  --help     Show this help"
      exit 0
      ;;
  esac
done

# Step 1: Build if requested
if [ "$DO_BUILD" = true ]; then
  echo -e "${YELLOW}Building Flutter web app...${NC}"

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
  echo -e "${YELLOW}Run with --build flag to build first: ./deploy-root.sh --build${NC}"
  exit 1
fi

# Step 3: Copy files to root repo
echo -e "${YELLOW}Copying build files to root repo...${NC}"

# Make sure the root repo exists and is up to date
if [ ! -d "$ROOT_REPO_DIR/.git" ]; then
  echo -e "${YELLOW}Cloning root repo...${NC}"
  git clone https://${GITHUB_TOKEN}@github.com/CHAMA18/chama18.github.io.git "$ROOT_REPO_DIR"
fi

cd "$ROOT_REPO_DIR"
git pull origin main 2>/dev/null || true

# Remove old files (keep .git)
find . -maxdepth 1 ! -name '.' ! -name '.git' ! -name '.gitignore' -exec rm -rf {} +

# Copy new files
cp -r "$BUILD_DIR"/* .

# ============================================================
# CRITICAL: NEVER create a CNAME file in this repo!
# CNAME causes GitHub Pages to use a custom domain, which
# breaks the chama18.github.io URL.
# ============================================================
if [ -f "CNAME" ]; then
  echo -e "${RED}WARNING: CNAME file found! Removing it to prevent custom domain redirect.${NC}"
  rm -f CNAME
fi

# Ensure .nojekyll exists to prevent Jekyll processing
touch .nojekyll

# Add 404.html for SPA routing (root version)
cat > 404.html << 'EOF404'
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>NDU Project - Redirecting...</title>
  <script>
    // SPA routing for GitHub Pages root site
    var path = window.location.pathname;
    if (path !== '/' && path !== '/index.html') {
      window.location.replace(window.location.origin + window.location.search + '#' + path);
    }
  </script>
</head>
<body>
  <p>Redirecting to NDU Project...</p>
</body>
</html>
EOF404

echo -e "${GREEN}Files copied and patched successfully${NC}"

# Step 4: Commit and push
echo -e "${YELLOW}Committing and pushing to root repo...${NC}"
git add -A
git commit --author="CHAMA18 <chungu424@gmail.com>" -m "Update root site: $(date '+%Y-%m-%d %H:%M')" 2>/dev/null || echo "No changes to commit"
git push origin main 2>&1

# ============================================================
# POST-DEPLOY VERIFICATION
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
PAGES_INFO=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/CHAMA18/chama18.github.io/pages 2>/dev/null || echo "")
if echo "$PAGES_INFO" | grep -q '"cname"'; then
  CNAME_VALUE=$(echo "$PAGES_INFO" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cname',''))" 2>/dev/null || echo "unknown")
  if [ -n "$CNAME_VALUE" ] && [ "$CNAME_VALUE" != "None" ] && [ "$CNAME_VALUE" != "null" ]; then
    echo -e "${RED}WARNING: Custom domain is set to '$CNAME_VALUE'. Removing it via API...${NC}"
    curl -s -X PUT -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3+json" \
      https://api.github.com/repos/CHAMA18/chama18.github.io/pages \
      -d '{"cname":null}' 2>/dev/null || true
  else
    echo -e "${GREEN}Verified: No custom domain set on GitHub Pages${NC}"
  fi
else
  echo -e "${GREEN}Verified: GitHub Pages configuration OK${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ROOT SITE DEPLOYED!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "  URL: ${CYAN}https://chama18.github.io/${NC}"
echo -e "  Dashboard: ${CYAN}https://chama18.github.io/#/dashboard${NC}"
echo -e "  Repo: ${CYAN}https://github.com/CHAMA18/chama18.github.io${NC}"
echo ""
echo -e "  Note: GitHub Pages may take 1-2 minutes to update."
echo ""
