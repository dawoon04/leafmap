-- 리프맵 × Supabase 초기 설정
-- Supabase 대시보드 → SQL Editor → New query 에 전체를 붙여넣고 Run 하세요.
-- 한 번만 실행하면 됩니다. 식당·메뉴 초기 데이터는 사이트를 처음 열 때 자동으로 채워집니다.

-- 1) 테이블 만들기 ------------------------------------------------------
create table if not exists public.restaurants (
  id     text primary key,          -- r1, r2 ...
  ko     text not null,             -- 한국어 식당명
  en     text,                      -- 영어 식당명
  area   text,                      -- haeundae / seomyeon
  addr   text,
  x      int,                       -- 지도 위 좌표(시연용)
  y      int,
  menus  jsonb not null default '[]'::jsonb,  -- 메뉴·재료·양념 제품·판정 근거
  ord    int default 0,
  updated_at timestamptz default now()
);

create table if not exists public.reports (      -- 정정 제보
  id      text primary key,
  menu_id text,
  who     text,
  text    text,
  cat     text,                     -- 관련 재료(meat, fish, shell ...)
  at      date,
  status  text,                     -- 접수 / 검토 중 / 반영 / 기각
  note    text,
  ord     bigint default 0,
  created_at timestamptz default now()
);

create table if not exists public.submissions (  -- 식당 신규 등록 자료
  id         text primary key,
  restaurant text,
  menu       text,
  files      jsonb default '[]'::jsonb,
  missing    jsonb default '[]'::jsonb,
  status     text,
  ord        bigint default 0,
  created_at timestamptz default now()
);

create table if not exists public.activity (     -- 운영 활동 기록
  id    text primary key,
  icon  text,
  title text,
  sub   text,
  ord   bigint default 0,
  created_at timestamptz default now()
);

-- 2) 문 열기(Grant) ------------------------------------------------------
-- 2026년 5월 30일 이후 만든 프로젝트는 이 줄이 없으면 웹페이지에서 테이블이 보이지 않습니다.
grant select, insert, update, delete on public.restaurants, public.reports, public.submissions, public.activity
  to anon, authenticated;

-- 3) RLS 켜기 + 정책 --------------------------------------------------------
-- 시연용 대시보드라서 로그인 없이 누구나 읽고 쓸 수 있게 열어 둡니다.
-- 실제 서비스에서는 운영자 로그인(Auth)을 붙이고 쓰기 정책을 authenticated 로 좁혀야 합니다.
alter table public.restaurants enable row level security;
alter table public.reports     enable row level security;
alter table public.submissions enable row level security;
alter table public.activity    enable row level security;

do $$
declare t text;
begin
  foreach t in array array['restaurants','reports','submissions','activity'] loop
    execute format('drop policy if exists "demo read"   on public.%I', t);
    execute format('drop policy if exists "demo insert" on public.%I', t);
    execute format('drop policy if exists "demo update" on public.%I', t);
    execute format('drop policy if exists "demo delete" on public.%I', t);
    execute format('create policy "demo read"   on public.%I for select to anon, authenticated using (true)', t);
    execute format('create policy "demo insert" on public.%I for insert to anon, authenticated with check (true)', t);
    execute format('create policy "demo update" on public.%I for update to anon, authenticated using (true) with check (true)', t);
    execute format('create policy "demo delete" on public.%I for delete to anon, authenticated using (true)', t);
  end loop;
end $$;
