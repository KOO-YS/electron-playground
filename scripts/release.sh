#!/bin/bash
# =============================================================
# release.sh - 로컬 빌드 후 GitHub Release 업로드
# 사용법: ./scripts/release.sh <버전> [플랫폼]
# 예시:   ./scripts/release.sh 1.0.0 mac
#         ./scripts/release.sh 1.0.0 win
#         ./scripts/release.sh 1.0.0 all
# =============================================================

set -e

# --- 파라미터 ---
VERSION=$1
PLATFORM=${2:-mac}  # 기본값: mac

if [ -z "$VERSION" ]; then
  echo "❌ 사용법: ./scripts/release.sh <버전> [mac|win|all]"
  echo "   예시: ./scripts/release.sh 1.0.0 mac"
  exit 1
fi

TAG="v${VERSION}"

echo "================================================"
echo "🚀 릴리스 시작: ${TAG} (플랫폼: ${PLATFORM})"
echo "================================================"

# --- 1. package.json 버전 업데이트 ---
echo ""
echo "📦 [1/5] package.json 버전 → ${VERSION}"
sed -i '' "s/\"version\": \".*\"/\"version\": \"${VERSION}\"/" package.json
echo "   ✅ 완료"

# --- 2. 빌드 ---
echo ""
echo "🔨 [2/5] 빌드 시작 (${PLATFORM})..."

# 이전 빌드 정리
rm -rf dist

if [ "$PLATFORM" = "mac" ]; then
  npm run build:mac
elif [ "$PLATFORM" = "win" ]; then
  npm run build:win
elif [ "$PLATFORM" = "all" ]; then
  npm run build:mac
  npm run build:win
else
  echo "   ❌ 알 수 없는 플랫폼: ${PLATFORM} (mac|win|all)"
  exit 1
fi
echo "   ✅ 빌드 완료"

# --- 3. 빌드 산출물 수집 ---
echo ""
echo "📁 [3/5] 빌드 산출물 확인..."

UPLOAD_FILES=()

# Mac 산출물
if [ "$PLATFORM" = "mac" ] || [ "$PLATFORM" = "all" ]; then
  DMG_FILE=$(find dist -name "*.dmg" -type f | head -1)
  ZIP_FILE=$(find dist -name "*.zip" -type f | head -1)
  MAC_YML="dist/latest-mac.yml"

  if [ -n "$DMG_FILE" ]; then
    echo "   📦 ${DMG_FILE} ($(du -h "$DMG_FILE" | cut -f1))"
    UPLOAD_FILES+=("$DMG_FILE")
  fi
  if [ -n "$ZIP_FILE" ]; then
    echo "   📦 ${ZIP_FILE} ($(du -h "$ZIP_FILE" | cut -f1))"
    UPLOAD_FILES+=("$ZIP_FILE")
  fi
  if [ -f "$MAC_YML" ]; then
    echo "   📄 ${MAC_YML}"
    UPLOAD_FILES+=("$MAC_YML")
  fi
fi

# Windows 산출물
if [ "$PLATFORM" = "win" ] || [ "$PLATFORM" = "all" ]; then
  EXE_FILE=$(find dist -name "*.exe" -type f | head -1)
  WIN_YML="dist/latest.yml"

  if [ -n "$EXE_FILE" ]; then
    echo "   📦 ${EXE_FILE} ($(du -h "$EXE_FILE" | cut -f1))"
    UPLOAD_FILES+=("$EXE_FILE")
  fi
  if [ -f "$WIN_YML" ]; then
    echo "   📄 ${WIN_YML}"
    UPLOAD_FILES+=("$WIN_YML")
  fi
fi

if [ ${#UPLOAD_FILES[@]} -eq 0 ]; then
  echo "   ❌ 업로드할 파일이 없습니다. 빌드를 확인해주세요."
  exit 1
fi

echo "   ✅ 총 ${#UPLOAD_FILES[@]}개 파일 확인"

# --- 4. Git 태그 생성 ---
echo ""
echo "🏷️  [4/5] Git 태그 생성: ${TAG}"
git add package.json
git commit -m "Release ${TAG}" || echo "   (변경사항 없음, 스킵)"
git tag -a "${TAG}" -m "Release ${TAG}"
echo "   ✅ 태그 생성 완료"

# --- 5. GitHub Release 생성 + 파일 업로드 ---
echo ""
echo "☁️  [5/5] GitHub Release 업로드 중..."

gh release create "${TAG}" \
  "${UPLOAD_FILES[@]}" \
  --title "${TAG}" \
  --notes "Release ${TAG}" \
  --latest

echo "   ✅ 업로드 완료"

# --- 완료 ---
echo ""
echo "================================================"
echo "✅ 릴리스 완료: ${TAG}"
echo "   GitHub Release 페이지에서 확인하세요."
echo "================================================"
