# Tokscale Team Deployment Guide

팀 내부에서 Tokscale을 운영하기 위한 가이드입니다.

## 목차

- [아키텍처 개요](#아키텍처-개요)
- [빠른 시작](#빠른-시작)
- [관리자: 서버 배포](#관리자-서버-배포)
- [팀원: CLI 설치](#팀원-cli-설치)
- [설정 커스터마이징](#설정-커스터마이징)
- [문제 해결](#문제-해결)

---

## 아키텍처 개요

```
┌─────────────────────────────────────────────────────────────────┐
│                        Team Infrastructure                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐      │
│   │  Team       │     │  Tokscale   │     │ PostgreSQL  │      │
│   │  Members    │────▶│  Dashboard  │────▶│  Database   │      │
│   │  (CLI)      │     │  (Next.js)  │     │             │      │
│   └─────────────┘     └─────────────┘     └─────────────┘      │
│         │                    │                                   │
│         │                    │                                   │
│         ▼                    ▼                                   │
│   ┌─────────────┐     ┌─────────────┐                          │
│   │ Local       │     │ GitHub      │                          │
│   │ Session     │     │ OAuth       │                          │
│   │ Data        │     │ (Auth)      │                          │
│   └─────────────┘     └─────────────┘                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**구성 요소:**
- **CLI**: 각 팀원의 로컬에서 토큰 사용량 분석
- **Dashboard**: 팀 리더보드 및 시각화 (선택사항)
- **Database**: 제출된 데이터 저장 (대시보드 사용 시)

---

## 빠른 시작

### 옵션 A: CLI만 사용 (가장 간단)

팀원들이 각자 CLI를 설치하고 로컬에서 사용:

```bash
# 원클릭 설치
curl -fsSL https://raw.githubusercontent.com/junhoyeo/tokscale/main/scripts/install.sh | bash

# 또는 직접 설치
curl -fsSL https://bun.sh/install | bash  # Bun 설치
bun add -g tokscale                        # tokscale 설치
```

### 옵션 B: 팀 대시보드 + CLI (권장)

중앙 대시보드를 배포하고 팀원들이 데이터를 제출:

1. 관리자가 Docker로 대시보드 배포
2. 팀원들이 CLI 설치 후 `tokscale submit`으로 데이터 제출
3. 웹에서 팀 리더보드 확인

---

## 관리자: 서버 배포

### 사전 요구사항

- Docker & Docker Compose 설치
- GitHub OAuth App (인증용)
- 내부 서버 또는 클라우드 인스턴스

### Step 1: 프로젝트 클론

```bash
git clone https://github.com/junhoyeo/tokscale.git
cd tokscale
```

### Step 2: 환경 설정

```bash
# 템플릿 복사
cp .env.team.example .env.team

# 설정 편집
nano .env.team
```

**필수 설정:**

```env
# PostgreSQL 비밀번호 (반드시 변경!)
POSTGRES_PASSWORD=your_secure_password_here

# GitHub OAuth (아래 가이드 참조)
GITHUB_CLIENT_ID=your_client_id
GITHUB_CLIENT_SECRET=your_client_secret

# 서버 URL (팀원들이 접근할 주소)
NEXT_PUBLIC_URL=http://tokscale.internal.company.com
```

### Step 3: GitHub OAuth App 생성

1. [GitHub Developer Settings](https://github.com/settings/developers) 접속
2. **New OAuth App** 클릭
3. 다음 정보 입력:
   - **Application name**: `Tokscale Team` (또는 원하는 이름)
   - **Homepage URL**: `http://your-server:3000`
   - **Authorization callback URL**: `http://your-server:3000/api/auth/github/callback`
4. **Register application** 클릭
5. Client ID와 Client Secret 복사

> **팁**: GitHub Organization의 OAuth App을 생성하면 조직 멤버만 접근하도록 제한할 수 있습니다.

### Step 4: 서비스 시작

```bash
# 백그라운드로 시작
docker-compose --env-file .env.team up -d

# 로그 확인
docker-compose logs -f

# 상태 확인
docker-compose ps
```

### Step 5: 데이터베이스 마이그레이션

```bash
# 컨테이너 접속
docker-compose exec frontend sh

# 마이그레이션 실행
bun run db:push
```

### 서비스 관리

```bash
# 중지
docker-compose down

# 재시작
docker-compose restart

# 업데이트
git pull
docker-compose build --no-cache
docker-compose up -d

# 데이터 백업
docker-compose exec postgres pg_dump -U tokscale tokscale > backup.sql
```

---

## 팀원: CLI 설치

### 자동 설치 (권장)

팀 내부 서버에서 스크립트를 호스팅하거나, 직접 실행:

```bash
# 옵션 1: GitHub에서 직접 설치
curl -fsSL https://raw.githubusercontent.com/junhoyeo/tokscale/main/scripts/install.sh | bash

# 옵션 2: 팀 서버에서 설치 (관리자가 스크립트 호스팅 시)
curl -fsSL https://tokscale.internal.company.com/install.sh | bash
```

### 수동 설치

```bash
# 1. Bun 설치
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc  # 또는 ~/.zshrc

# 2. tokscale 설치
bun add -g tokscale

# 3. 설치 확인
tokscale --version
```

### 기본 사용법

```bash
# TUI 대시보드 실행
tokscale

# 테이블 형식으로 보기
tokscale --light

# 이번 주 사용량
tokscale --week

# 모델별 상세 분석
tokscale models

# 팀 리더보드에 제출
tokscale login          # GitHub 로그인
tokscale submit         # 데이터 제출
```

### 권장 설정

`~/.config/tokscale/settings.json`:

```json
{
  "colorPalette": "blue",
  "includeUnusedModels": false,
  "autoRefreshEnabled": true,
  "autoRefreshMs": 60000
}
```

### Claude Code 히스토리 보존

정확한 추적을 위해 자동 삭제 비활성화:

`~/.claude/settings.json`:
```json
{
  "cleanupPeriodDays": 9999999999
}
```

---

## 설정 커스터마이징

### CLI 설정 옵션

| 설정 | 기본값 | 설명 |
|------|--------|------|
| `colorPalette` | `"green"` | 테마: green, blue, pink, purple, orange 등 |
| `includeUnusedModels` | `false` | 사용량 0인 모델 표시 |
| `autoRefreshEnabled` | `false` | TUI 자동 새로고침 |
| `autoRefreshMs` | `60000` | 새로고침 간격 (ms) |

### 환경 변수

| 변수 | 설명 |
|------|------|
| `TOKSCALE_NATIVE_TIMEOUT_MS` | 네이티브 프로세스 타임아웃 (기본: 300000) |
| `TOKSCALE_MAX_OUTPUT_BYTES` | 최대 출력 크기 (기본: 104857600) |
| `DEBUG` | 디버그 로깅 활성화 |

---

## 문제 해결

### CLI 관련

**"bun: command not found"**
```bash
# Bun 재설치
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc
```

**"tokscale: command not found"**
```bash
# 전역 설치 확인
bun pm ls -g

# PATH에 추가
export PATH="$HOME/.bun/bin:$PATH"
```

### 서버 관련

**데이터베이스 연결 실패**
```bash
# PostgreSQL 컨테이너 상태 확인
docker-compose ps postgres

# 로그 확인
docker-compose logs postgres
```

**GitHub OAuth 오류**
- Callback URL이 정확히 일치하는지 확인
- `NEXT_PUBLIC_URL`이 실제 접속 URL과 일치하는지 확인

**포트 충돌**
```bash
# .env.team에서 포트 변경
FRONTEND_PORT=3001
POSTGRES_PORT=5433
```

### 데이터 관련

**세션 데이터가 안 보임**
- 각 플랫폼의 데이터 위치 확인:
  - Claude Code: `~/.claude/projects/`
  - Cursor: API 연동 필요 (`tokscale cursor login`)
  - Gemini: `~/.gemini/tmp/*/chats/`

**비용 계산이 부정확함**
- 가격 캐시 삭제: `rm -rf ~/.cache/tokscale/`
- 최신 버전 업데이트: `bun add -g tokscale@latest`

---

## 지원

- GitHub Issues: https://github.com/junhoyeo/tokscale/issues
- 문서: https://github.com/junhoyeo/tokscale#readme
