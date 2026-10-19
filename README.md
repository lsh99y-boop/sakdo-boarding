# 계룡산 삭도 탑승 기록 (Supabase + Vercel)

단일 HTML 웹앱입니다. 데이터는 **Supabase**(PostgreSQL)에 저장하고 **Vercel**에 정적 배포합니다.
Supabase 설정 전에는 자동으로 "이 기기 저장(localStorage)" 모드로 동작합니다.

## 구성 파일
- `index.html` — 앱 본체(배포 대상)
- `config.js` — Supabase 접속 정보(여기만 채우면 됨)
- `supabase/schema.sql` — Supabase에 한 번 실행할 테이블/정책/실시간 설정
- `vercel.json` / `.vercelignore` — 배포 설정
- `삭도_일일탑승일지.html` — 기존 claude.ai 아티팩트 원본(배포에서는 제외됨)

## 1. Supabase 테이블 만들기 (기존 업무일지 프로젝트 재사용 가능)
1. Supabase 대시보드에서 쓰던 프로젝트를 엽니다.
2. 왼쪽 **SQL Editor → New query**.
3. `supabase/schema.sql` 내용을 전부 붙여넣고 **Run**.
   - 모든 테이블은 `sakdo_` 접두어(`sakdo_entries`, `sakdo_permits`, `sakdo_config`)라 기존 업무일지 테이블과 겹치지 않습니다.
   - 여러 번 실행해도 안전합니다.

## 2. 접속 키 넣기
1. Supabase: **Project Settings → API**.
2. **Project URL** 과 **anon public** 키를 복사.
3. `config.js` 의 두 값을 채웁니다.
   ```js
   window.SUPABASE_URL      = "https://xxxx.supabase.co";
   window.SUPABASE_ANON_KEY = "eyJhbGciOi...";   // anon public 키
   ```
   > anon(public) 키는 공개용이라 커밋·배포해도 됩니다. **service_role(비밀) 키는 넣지 마세요.**

## 3. 로컬에서 확인
브라우저 보안상 `index.html`을 더블클릭(file://)하면 Supabase 연결이 막힐 수 있으니 간단한 로컬 서버로 엽니다.
```bash
# 이 폴더에서
python -m http.server 8080
# 그다음 브라우저에서 http://localhost:8080 접속
```
- 우상단/표지에 별도 표시는 없지만, 기록을 저장한 뒤 Supabase **Table Editor → sakdo_entries** 에 행이 생기면 연결 성공입니다.
- 키를 안 채웠으면 자동으로 이 기기(localStorage) 모드로 동작합니다.

## 4. Vercel 배포
### GitHub 연동 (권장)
1. 이 폴더를 GitHub 저장소로 push.
2. [vercel.com](https://vercel.com) → **Add New… → Project → Import** 해당 저장소.
3. **Framework Preset: Other**, Build/Output 설정 없음(그대로 Deploy).
4. 배포 완료 후 주소(예: `https://sakdo.vercel.app`)가 생깁니다. 앱의 **QR·공유**는 이 배포 주소를 자동으로 가리킵니다.

### 또는 Vercel CLI
```bash
npm i -g vercel
vercel          # 최초 1회: 로그인 + 프로젝트 생성
vercel --prod   # 운영 배포
```

## 보안 메모
- 현재 정책은 anon 공개키로 읽기/쓰기를 허용하고, 앱 내 **PIN**으로 열람을 통제합니다(소프트 게이트).
- 더 강한 보안이 필요하면 Supabase **Auth**(로그인) + 사용자 기반 RLS 정책으로 전환하세요. 필요 시 작업해 드립니다.
