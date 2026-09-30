-- =========================================================
-- 共用行事曆：Supabase 資料表設定
-- 用法：Supabase 後台 → SQL Editor → New query → 貼上全部 → Run
-- =========================================================

-- 每日事項
create table if not exists public.todos (
  id          uuid primary key default gen_random_uuid(),
  "date"      text not null,                 -- 2026-10-06
  "text"      text not null,                 -- 名稱
  "time"      text not null default '',      -- 14:00（可空白）
  note        text not null default '',      -- 備註
  color       text not null default 'lunar',
  done        boolean not null default false,
  done_at     bigint,
  done_by     text,
  deleted_at  bigint,                        -- 放進垃圾桶的時間（毫秒）
  deleted_by  text,
  created_at  bigint not null default (extract(epoch from now()) * 1000)::bigint,
  created_by  text
);

-- 備註欄（整月待辦）
create table if not exists public.memos (
  id             uuid primary key default gen_random_uuid(),
  month          text not null,              -- 2026-10
  "text"         text not null,
  color          text not null default 'lunar',
  deadline       text not null default '',   -- 2026-10-12（可空白）
  deadline_time  text not null default '',   -- 17:00（可空白）
  done           boolean not null default false,
  done_at        bigint,
  done_by        text,
  deleted_at     bigint,
  deleted_by     text,
  created_at     bigint not null default (extract(epoch from now()) * 1000)::bigint,
  created_by     text
);

create index if not exists todos_date_idx  on public.todos ("date");
create index if not exists memos_month_idx on public.memos (month);

-- 權限：任何拿到網址的人都可以讀寫（見 README 的安全性說明）
alter table public.todos enable row level security;
alter table public.memos enable row level security;

drop policy if exists "todos_all" on public.todos;
create policy "todos_all" on public.todos
  for all to anon, authenticated using (true) with check (true);

drop policy if exists "memos_all" on public.memos;
create policy "memos_all" on public.memos
  for all to anon, authenticated using (true) with check (true);

-- 即時同步
alter table public.todos replica identity full;
alter table public.memos replica identity full;

do $$
begin
  begin
    alter publication supabase_realtime add table public.todos;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.memos;
  exception when duplicate_object then null;
  end;
end $$;

-- ---------------------------------------------------------
-- （選用）每天凌晨 3 點自動清除垃圾桶中超過 14 天的項目。
-- 網頁開啟時本來就會自動清除；若也想在伺服器端清，
-- 先到 Database → Extensions 啟用 pg_cron，再執行下面這段：
--
-- select cron.schedule('purge-calendar-trash', '0 19 * * *', $$
--   delete from public.todos where deleted_at < (extract(epoch from now()) * 1000 - 14 * 86400000);
--   delete from public.memos where deleted_at < (extract(epoch from now()) * 1000 - 14 * 86400000);
-- $$);
-- （'0 19 * * *' 是 UTC 19:00，也就是台灣時間凌晨 3 點）
