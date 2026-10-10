#!/usr/bin/env bash
# Script to build and generate the Lodge House site locally
# Usage: ./scripts/build-site.sh [base-url]

set -euo pipefail

BASE_URL=${1:-https://lean-workers-union.github.io}
PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LODGE_API_DIR="$PROJECT_ROOT/.letta/worktrees/lodge-house-api"

echo "=== Building Lodge House Site ==="
echo "Base URL: $BASE_URL"
echo "Project root: $PROJECT_ROOT"
echo "Lodge API dir: $LODGE_API_DIR"

# Build the core project
echo -e "\n[1/3] Building ChoirUnion core..."
cd "$PROJECT_ROOT"
lake build 2>&1 | tee build.log
if grep -qi "warning" build.log; then
  echo "⚠️  Build produced warnings (check build.log)"
  exit 1
fi
echo "✅ Core build successful"

# Generate the site
echo -e "\n[2/3] Generating static site..."
cd "$LODGE_API_DIR"
lake exe lodge-gen -- site-out "$BASE_URL" 2>&1 | tee generate.log
if [ ! -f site-out/index.html ]; then
  echo "❌ Site generation failed - site-out/index.html not found"
  exit 1
fi
echo "✅ Site generated successfully"

# Verification
echo -e "\n[3/3] Verifying site output..."
ls -la "$LODGE_API_DIR/site-out/" | head -10
echo ""
echo "=== Build Complete ==="
echo "Site generated in: $LODGE_API_DIR/site-out"
echo "To test locally:"
echo "  python3 -m http.server 8080 --directory $LODGE_API_DIR/site-out"
echo "  Then visit: http://localhost:8080"