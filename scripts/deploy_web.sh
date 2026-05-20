#!/usr/bin/env bash
# AfriMarket — Build + stage Flutter web for Vercel deployment
# Usage: bash scripts/deploy_web.sh
set -euo pipefail

FLUTTER="${FLUTTER:-/home/martin/flutter/bin/flutter}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Building Flutter web (release)..."
cd "$ROOT"
"$FLUTTER" build web --release --base-href / --no-wasm-dry-run

echo "==> Staging build/web for git..."
git add -f build/web/
git add .gitignore vercel.json web/

echo ""
echo "✓ Build complete. Files staged."
echo ""
echo "  Next steps:"
echo "  1. git commit -m 'chore: update web build for Vercel deployment'"
echo "  2. git push origin main"
echo "  3. Vercel will auto-deploy from build/web/ (no build command needed)"
echo ""
echo "  Vercel environment vars to set in dashboard:"
echo "    SUPABASE_URL       = (from .env.production)"
echo "    SUPABASE_ANON_KEY  = (from .env.production)"
