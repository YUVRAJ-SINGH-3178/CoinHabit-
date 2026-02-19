-- Phase 6 leaderboard schema scaffold

create extension if not exists pgcrypto;

create table if not exists public.leaderboard_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  username text,
  avatar_url text,
  coins_this_week integer not null default 0,
  rank integer,
  week_start date not null default date_trunc('week', now())::date,
  created_at timestamptz not null default now()
);

create index if not exists leaderboard_week_rank_idx
  on public.leaderboard_snapshots(week_start, rank);
create index if not exists leaderboard_user_idx
  on public.leaderboard_snapshots(user_id);

alter table public.leaderboard_snapshots enable row level security;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'leaderboard_snapshots' AND policyname = 'leaderboard_read_authenticated'
  ) THEN
    CREATE POLICY leaderboard_read_authenticated
      ON public.leaderboard_snapshots
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;
