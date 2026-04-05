# Electron Auto Update - 테스트 가이드

## 전체 흐름

```
[Mac에서 로컬 빌드 (electron-builder)]
       ↓
[gh release create → .dmg/.zip + latest-mac.yml 업로드]
   또는 [gh release create → .exe + latest.yml 업로드]
       ↓
[앱 실행 → GitHub Release의 yml 체크 → 업데이트 감지 → 다운로드 → 설치]
```

> **참고**: PyArmor가 가상화 환경(Docker/CI)을 지원하지 않으므로 GitHub Actions 대신 로컬 빌드 방식을 사용합니다.

---

## 1. 사전 설정

### 필요 도구 설치 (Mac)

```bash
# gh CLI (GitHub Release 업로드용)
brew install gh
gh auth login

# Wine (Windows 크로스 빌드 시 필요)
brew install --cask wine-stable

# Node.js (v18+)
brew install node
```

### package.json `build.publish` 수정

```json
"publish": {
  "provider": "github",
  "owner": "YOUR_GITHUB_USERNAME",
  "repo": "YOUR_REPO_NAME"
}
```

```bash
npm install
```

---

## 2. 빌드 명령어

```bash
# Mac 빌드 (.dmg + .zip)
npm run build:mac

# Windows 크로스 빌드 (.exe) — Wine 필요
npm run build:win
```

---

## 3. 첫 릴리스 (v1.0.0)

### 방법 A: 릴리스 스크립트 사용 (권장)

```bash
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main

# Mac 빌드 + 릴리스 (기본값)
./scripts/release.sh 1.0.0 mac

# Windows 빌드 + 릴리스
./scripts/release.sh 1.0.0 win

# 둘 다
./scripts/release.sh 1.0.0 all
```

스크립트가 자동으로: 버전 업데이트 → 빌드 → Git 태그 → GitHub Release 업로드를 처리합니다.

### 방법 B: 수동

```bash
# 1. 빌드
npm run build:mac

# 2. Git 태그
git tag v1.0.0
git push origin main --tags

# 3. GitHub Release 생성 + 업로드
gh release create v1.0.0 \
  dist/*.dmg \
  dist/*.zip \
  dist/latest-mac.yml \
  --title "v1.0.0" \
  --notes "Initial release"
```

빌드 후 Mac에서는 `.dmg`를 열어 설치합니다.

---

## 4. 업데이트 릴리스 (v1.1.0)

```bash
# 코드 수정 후 릴리스 스크립트 실행
./scripts/release.sh 1.1.0 mac
```

또는 수동으로:

```bash
# package.json version을 "1.1.0"으로 변경 후

npm run build:mac

git add .
git commit -m "v1.1.0"
git tag v1.1.0
git push origin main --tags

gh release create v1.1.0 \
  dist/*.dmg \
  dist/*.zip \
  dist/latest-mac.yml \
  --title "v1.1.0" \
  --notes "Release v1.1.0"
```

---

## 5. 업데이트 확인

설치된 v1.0.0 앱을 실행하면:
1. 3초 후 자동으로 GitHub Release의 `latest-mac.yml` (또는 `latest.yml`) 확인
2. v1.1.0 감지 → "새 버전 발견" 표시
3. 다운로드 → 설치 및 재시작

> **Mac과 Windows의 auto-update 동작은 동일합니다.** Mac에서 `.dmg`로 테스트한 결과가 Windows `.exe`에도 그대로 적용됩니다.

---

## 트러블슈팅

- **업데이트 미동작 시**: `build.publish.owner` / `repo` 값 확인, Release가 Draft가 아닌지 확인, `latest-mac.yml`(또는 `latest.yml`)이 Release에 업로드되었는지 확인
- **개발 모드(`npm start`)에서는 auto-update 동작 안 함** — 반드시 설치된 앱에서 테스트
- **Mac Gatekeeper 경고**: 코드 서명 없이 빌드하면 "확인되지 않은 개발자" 경고 표시. 본인 Mac에서는 시스템 설정에서 허용 가능
- **Windows SmartScreen 경고**: "추가 정보 → 실행"으로 우회 가능
- **Apple Silicon Mac에서 Wine 문제 시**: Windows 빌드는 별도 Windows PC에서 진행하거나, `--win` 없이 Mac 빌드만 먼저 테스트
