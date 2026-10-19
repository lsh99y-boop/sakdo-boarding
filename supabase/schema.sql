-- 계룡산 삭도 탑승 기록 앱 — Supabase 스키마
-- 기존 "업무일지" 등 다른 테이블과 충돌하지 않도록 모두 sakdo_ 접두어를 사용합니다.
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 [Run] 하세요. (여러 번 실행해도 안전)

-- 1) 테이블: 각 레코드 객체 전체를 payload(jsonb)에 저장
create table if not exists public.sakdo_entries (
  id          text primary key,
  payload     jsonb not null,
  inserted_at timestamptz not null default now()
);
create table if not exists public.sakdo_permits (
  id          text primary key,
  payload     jsonb not null,
  inserted_at timestamptz not null default now()
);
create table if not exists public.sakdo_config (
  id          text primary key,
  payload     jsonb not null,
  inserted_at timestamptz not null default now()
);

-- 2) 일자별 조회 성능용 인덱스
create index if not exists sakdo_entries_date_idx on public.sakdo_entries ((payload->>'date'));

-- 3) RLS 활성화
alter table public.sakdo_entries enable row level security;
alter table public.sakdo_permits enable row level security;
alter table public.sakdo_config  enable row level security;

-- 4) 익명(anon) 공개키로 읽기/쓰기 허용 — 앱 내 PIN으로 열람을 통제합니다.
--    ⚠ 공개 anon 키가 노출되면 누구나 이 테이블을 읽고 쓸 수 있습니다.
--      강한 보안이 필요하면 Supabase Auth(로그인) + 사용자 기반 정책으로 전환을 권장합니다.
do $$
declare t text;
begin
  foreach t in array array['sakdo_entries','sakdo_permits','sakdo_config'] loop
    execute format('drop policy if exists %I on public.%I', t || '_anon_all', t);
    execute format('create policy %I on public.%I for all to anon using (true) with check (true)', t || '_anon_all', t);
  end loop;
end $$;

-- 5) 실시간(Realtime) 반영 — 여러 기기에서 즉시 동기화
do $$
begin
  begin alter publication supabase_realtime add table public.sakdo_entries; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.sakdo_permits; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.sakdo_config;  exception when duplicate_object then null; end;
end $$;
