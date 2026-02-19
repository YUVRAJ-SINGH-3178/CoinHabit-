-- Production baseline schema for CoinHabit (idempotent)
-- Run in Supabase SQL Editor (or `supabase db push`) on your target project.

create extension if not exists pgcrypto;

-- Ensure profiles has columns used by the app/check-in flow
alter table if exists public.profiles
  add column if not exists coins integer not null default 0,
  add column if not exists xp integer not null default 0,
  add column if not exists level integer not null default 1,
  add column if not exists streak_current integer not null default 0,
  add column if not exists streak_longest integer not null default 0,
  add column if not exists streak_freezes integer not null default 0,
  add column if not exists last_checkin_date timestamptz,
  add column if not exists notification_time text,
  add column if not exists updated_at timestamptz not null default now();

-- Goals table
create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  category text not null,
  emoji text,
  target_amount numeric(12,2) not null check (target_amount > 0),
  saved_amount numeric(12,2) not null default 0 check (saved_amount >= 0),
  deadline timestamptz,
  status text not null default 'active' check (status in ('active', 'completed', 'paused')),
  color_theme text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create index if not exists goals_user_id_idx on public.goals(user_id);
create index if not exists goals_created_at_idx on public.goals(created_at desc);

-- Deposits table
create table if not exists public.deposits (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.goals(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  amount numeric(12,2) not null check (amount > 0),
  note text,
  coins_earned integer not null default 0,
  xp_earned integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists deposits_user_id_idx on public.deposits(user_id);
create index if not exists deposits_goal_id_idx on public.deposits(goal_id);
create index if not exists deposits_created_at_idx on public.deposits(created_at desc);

-- RLS
alter table public.goals enable row level security;
alter table public.deposits enable row level security;

-- Goals policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'goals' AND policyname = 'goals_select_own'
  ) THEN
    CREATE POLICY goals_select_own ON public.goals
      FOR SELECT USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'goals' AND policyname = 'goals_insert_own'
  ) THEN
    CREATE POLICY goals_insert_own ON public.goals
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'goals' AND policyname = 'goals_update_own'
  ) THEN
    CREATE POLICY goals_update_own ON public.goals
      FOR UPDATE USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'goals' AND policyname = 'goals_delete_own'
  ) THEN
    CREATE POLICY goals_delete_own ON public.goals
      FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- Deposits policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'deposits' AND policyname = 'deposits_select_own'
  ) THEN
    CREATE POLICY deposits_select_own ON public.deposits
      FOR SELECT USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'deposits' AND policyname = 'deposits_insert_own'
  ) THEN
    CREATE POLICY deposits_insert_own ON public.deposits
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'deposits' AND policyname = 'deposits_update_own'
  ) THEN
    CREATE POLICY deposits_update_own ON public.deposits
      FOR UPDATE USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'deposits' AND policyname = 'deposits_delete_own'
  ) THEN
    CREATE POLICY deposits_delete_own ON public.deposits
      FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- Keep goals.saved_amount in sync with deposits
create or replace function public.sync_goal_saved_amount()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.goals
      set saved_amount = coalesce(saved_amount, 0) + new.amount
    where id = new.goal_id;
    return new;
  elsif tg_op = 'UPDATE' then
    if new.goal_id = old.goal_id then
      update public.goals
        set saved_amount = greatest(0, coalesce(saved_amount, 0) - old.amount + new.amount)
      where id = new.goal_id;
    else
      update public.goals
        set saved_amount = greatest(0, coalesce(saved_amount, 0) - old.amount)
      where id = old.goal_id;

      update public.goals
        set saved_amount = coalesce(saved_amount, 0) + new.amount
      where id = new.goal_id;
    end if;
    return new;
  elsif tg_op = 'DELETE' then
    update public.goals
      set saved_amount = greatest(0, coalesce(saved_amount, 0) - old.amount)
    where id = old.goal_id;
    return old;
  end if;

  return null;
end;
$$;

drop trigger if exists trg_sync_goal_saved_amount on public.deposits;
create trigger trg_sync_goal_saved_amount
after insert or update or delete on public.deposits
for each row execute function public.sync_goal_saved_amount();

-- RPC used by profile chart widget: returns yyyy-MM + total for last 6 months
create or replace function public.get_monthly_savings(p_user_id uuid)
returns table (month text, total numeric)
language sql
stable
security invoker
set search_path = public
as $$
  select
    to_char(date_trunc('month', d.created_at), 'YYYY-MM') as month,
    coalesce(sum(d.amount), 0)::numeric as total
  from public.deposits d
  where d.user_id = p_user_id
    and d.created_at >= date_trunc('month', now()) - interval '5 months'
  group by 1
  order by 1;
$$;

-- RPC used by app check-in flow (preferred over edge fallback)
create or replace function public.process_checkin()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_last_checkin timestamptz;
  v_streak_current integer;
  v_streak_longest integer;
  v_coins integer;
  v_next_streak integer;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select
    p.last_checkin_date,
    coalesce(p.streak_current, 0),
    coalesce(p.streak_longest, 0),
    coalesce(p.coins, 0)
  into
    v_last_checkin,
    v_streak_current,
    v_streak_longest,
    v_coins
  from public.profiles p
  where p.id = v_user_id
  for update;

  if not found then
    raise exception 'Profile row not found for user %', v_user_id;
  end if;

  if v_last_checkin::date = now()::date then
    return jsonb_build_object('status', 'already_checked_in');
  end if;

  if v_last_checkin is not null and v_last_checkin::date = (now()::date - 1) then
    v_next_streak := v_streak_current + 1;
  else
    v_next_streak := 1;
  end if;

  update public.profiles
  set
    coins = v_coins + 10,
    streak_current = v_next_streak,
    streak_longest = greatest(v_streak_longest, v_next_streak),
    last_checkin_date = now(),
    updated_at = now()
  where id = v_user_id;

  return jsonb_build_object('status', 'ok', 'coins_earned', 10, 'streak_current', v_next_streak);
end;
$$;

grant execute on function public.get_monthly_savings(uuid) to authenticated;
grant execute on function public.process_checkin() to authenticated;
