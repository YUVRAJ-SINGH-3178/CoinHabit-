-- Phase 4 RPC scaffolding for deposits + weekly chart

create or replace function public.process_deposit(
  p_goal_id uuid,
  p_amount numeric,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_target numeric;
  v_saved_before numeric;
  v_saved_after numeric;
  v_progress_before numeric;
  v_progress_after numeric;
  v_milestone integer;
  v_goal_completed boolean;
  v_coins integer;
  v_xp integer;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Amount must be greater than zero';
  end if;

  select g.target_amount, g.saved_amount
  into v_target, v_saved_before
  from public.goals g
  where g.id = p_goal_id
    and g.user_id = v_user_id
  for update;

  if not found then
    raise exception 'Goal not found';
  end if;

  v_saved_after := coalesce(v_saved_before, 0) + p_amount;
  v_progress_before := case when v_target > 0 then (coalesce(v_saved_before, 0) / v_target) * 100 else 0 end;
  v_progress_after := case when v_target > 0 then (v_saved_after / v_target) * 100 else 0 end;

  v_milestone := null;
  if v_progress_before < 25 and v_progress_after >= 25 then
    v_milestone := 25;
  elsif v_progress_before < 50 and v_progress_after >= 50 then
    v_milestone := 50;
  elsif v_progress_before < 75 and v_progress_after >= 75 then
    v_milestone := 75;
  elsif v_progress_before < 100 and v_progress_after >= 100 then
    v_milestone := 100;
  end if;

  v_goal_completed := v_progress_after >= 100;
  v_coins := case when v_milestone is null then 15 else 65 end;
  v_xp := case when v_milestone is null then 10 else 40 end;

  insert into public.deposits (
    goal_id,
    user_id,
    amount,
    note,
    coins_earned,
    xp_earned
  ) values (
    p_goal_id,
    v_user_id,
    p_amount,
    p_note,
    v_coins,
    v_xp
  );

  update public.goals
  set
    status = case when v_goal_completed then 'completed' else status end,
    completed_at = case when v_goal_completed then now() else completed_at end
  where id = p_goal_id;

  return jsonb_build_object(
    'success', true,
    'milestone_hit', v_milestone,
    'goal_completed', v_goal_completed,
    'coins_earned', v_coins,
    'xp_earned', v_xp
  );
end;
$$;

grant execute on function public.process_deposit(uuid, numeric, text) to authenticated;

create or replace function public.get_weekly_savings(p_user_id uuid)
returns table (weekday integer, total_amount numeric)
language sql
stable
security invoker
set search_path = public
as $$
  select
    extract(isodow from d.created_at)::int as weekday,
    coalesce(sum(d.amount), 0)::numeric as total_amount
  from public.deposits d
  where d.user_id = p_user_id
    and d.created_at >= (current_date - interval '6 day')
  group by 1
  order by 1;
$$;

grant execute on function public.get_weekly_savings(uuid) to authenticated;
