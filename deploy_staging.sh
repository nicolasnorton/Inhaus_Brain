#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# InhausBrain — Staging Deployment Script
# Deploys ONLY to inhausbrain-beta.web.app (Firebase Hosting)
# NEVER touches production (brain.inhauscorp.com / Cloud Run)
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}  InhausBrain — Staging Deployment${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"

# ── Safety: Verify we're NOT on main ──────────────────────────
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
  echo -e "${RED}❌ ERROR: Cannot deploy to staging from main/master branch!${NC}"
  echo -e "${RED}   Switch to your feature branch first.${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Branch: ${CURRENT_BRANCH}${NC}"

# ── Load .env if present ──────────────────────────────────────
if [ -f .env ]; then
  echo -e "${YELLOW}Loading .env...${NC}"
  export $(grep -v '^#' .env | xargs)
fi

# ── Verify required keys ─────────────────────────────────────
if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo -e "${RED}❌ GEMINI_API_KEY not set! Add to .env or export.${NC}"
  exit 1
fi
echo -e "${GREEN}✓ API keys loaded${NC}"

# ── Step 1: Flutter Build (Staging) ──────────────────────────
echo -e "\n${YELLOW}[1/3] Building Flutter web (staging)...${NC}"
flutter build web --release \
  --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
  --dart-define=ENVIRONMENT=staging

echo -e "${GREEN}✓ Build complete${NC}"

# ── Step 2: Deploy Firebase Hosting (Beta ONLY) ──────────────
echo -e "\n${YELLOW}[2/3] Deploying to Firebase Hosting (inhaus-brain → inhausbrain-beta)...${NC}"
firebase deploy --only hosting:inhaus-brain

echo -e "${GREEN}✓ Hosting deployed${NC}"

# ── Step 3: Optional Functions Deploy ─────────────────────────
echo -e "\n${YELLOW}[3/3] Deploying Cloud Functions...${NC}"
read -p "Deploy Cloud Functions? (y/N): " DEPLOY_FUNCTIONS
if [[ "$DEPLOY_FUNCTIONS" =~ ^[Yy]$ ]]; then
  firebase deploy --only functions
  echo -e "${GREEN}✓ Functions deployed${NC}"
else
  echo -e "${YELLOW}⏭  Skipped functions deploy${NC}"
fi

# ── Done ──────────────────────────────────────────────────────
echo -e "\n${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Staging deployment complete!${NC}"
echo -e "${GREEN}  🌐 https://inhausbrain-beta.web.app${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}⚠️  Production (brain.inhauscorp.com) was NOT touched.${NC}"
