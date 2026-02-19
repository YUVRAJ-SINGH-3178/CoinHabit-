-- Phase 5 rewards schema (badges)

create extension if not exists pgcrypto;

create table if not exists public.badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  badge_key text not null,
  badge_name text not null,
  badge_rarity text not null,
  earned_at timestamptz not null default now()
);

create unique index if not exists badges_user_badge_key_uidx
  on public.badges(user_id, badge_key);
create index if not exists badges_user_id_idx on public.badges(user_id);
create index if not exists badges_earned_at_idx on public.badges(earned_at desc);

alter table public.badges enable row level security;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'badges' AND policyname = 'badges_select_own'
  ) THEN
    CREATE POLICY badges_select_own ON public.badges
      FOR SELECT USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'badges' AND policyname = 'badges_insert_own'
  ) THEN
    CREATE POLICY badges_insert_own ON public.badges
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'badges' AND policyname = 'badges_delete_own'
  ) THEN
    CREATE POLICY badges_delete_own ON public.badges
      FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;
