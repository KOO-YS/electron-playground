#!/bin/bash
# =============================================================
# upload.sh - 빌드 산출물을 GitHub Release에 업로드
# 사용법: ./scripts/upload.sh <버전> [플랫폼]
# 예시:   ./scripts/upload.sh 1.0.0 mac
#         ./scripts/upload.sh 1.0.0 win
#         ./scripts/upload.sh 1.0.0 all
# (build.sh 실행 후 사용)
# =============================================================

set -e

VERSION=$1
PLATFORM=${2:-mac}

if [ -z "$VERSION" ]; then
  echo "사용법: ./scripts/upload.sh <버전> [mac|win|all]"
  exit 1
fi

TAG="v${VERSION}"

UPLOAD_FILES=()

if [ "$PLATFORM" = "mac" ] || [ "$PLATFORM" = "all" ]; then
  DMG_FILE=$(find dist -name "*.dmg" -type f | head -1)
  ZIP_FILE=$(find dist -name "*.zip" -type f | head -1)
  [ -n "$DMG_FILE" ] && UPLOAD_FILES+=("$DMG_FILE")
  [ -n "$ZIP_FILE" ] && UPLOAD_FILES+=("$ZIP_FILE")
  [ -f "dist/latest-mac.yml" ] && UPLOAD_FILES+=("dist/latest-mac.yml")
fi

if [ "$PLATFORM" = "win" ] || [ "$PLATFORM" = "all" ]; then
  EXE_FILE=$(find dist -name "*.exe" -type f | head -1)
  [ -n "$EXE_FILE" ] && UPLOAD_FILES+=("$EXE_FILE")
  [ -f "dist/latest.yml" ] && UPLOAD_FILES+=("dist/latest.yml")
fi

if [ ${#UPLOAD_FILES[@]} -eq 0 ]; then
  echo "업로드할 파일이 없습니다. build.sh를 먼저 실행하세요."
  exit 1
fi

echo "▶ Git 태그 생성: ${TAG}"
git add package.json
git commit -m "Release ${TAG}" || echo "  (변경사항 없음, 스킵)"
git tag -a "${TAG}" -m "Release ${TAG}"
git push origin main --tags

echo "▶ GitHub Release 업로드: ${TAG}"
gh release create "${TAG}" \
  "${UPLOAD_FILES[@]}" \
  --title "${TAG}" \
  --notes "Release ${TAG}" \
  --latest

echo "✅ 완료: ${TAG}"