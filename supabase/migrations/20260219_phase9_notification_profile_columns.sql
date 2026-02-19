-- Phase 9: notification profile columns

alter table if exists public.profiles
  add column if not exists fcm_token text,
  add column if not exists fcm_token_updated_at timestamptz;
