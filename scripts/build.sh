#!/bin/bash
# =============================================================
# build.sh - 로컬 빌드
# 사용법: ./scripts/build.sh <버전> [플랫폼]
# 예시:   ./scripts/build.sh 1.0.0 mac
#         ./scripts/build.sh 1.0.0 win
#         ./scripts/build.sh 1.0.0 all
# =============================================================

set -e

VERSION=$1
PLATFORM=${2:-mac}

if [ -z "$VERSION" ]; then
  echo "사용법: ./scripts/build.sh <버전> [mac|win|all]"
  exit 1
fi

echo "▶ package.json 버전 → ${VERSION}"
sed -i '' "s/\"version\": \".*\"/\"version\": \"${VERSION}\"/" package.json

echo "▶ dist/ 정리"
rm -rf dist

echo "▶ 빌드 시작 (${PLATFORM})"
if [ "$PLATFORM" = "mac" ]; then
  npm run build:mac
elif [ "$PLATFORM" = "win" ]; then
  npm run build:win
elif [ "$PLATFORM" = "all" ]; then
  npm run build:mac
  npm run build:win
else
  echo "알 수 없는 플랫폼: ${PLATFORM} (mac|win|all)"
  exit 1
fi

echo "✅ 빌드 완료 → dist/"
ls dist/