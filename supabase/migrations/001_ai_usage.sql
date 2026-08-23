-- supabase/migrations/001_ai_usage.sql
--
-- AI usage tracking table for rate limiting and quota enforcement.
-- Used by the ai-chat Edge Function to enforce per-user rate limits.

-- Enable UUID extension if not already enabled
create extension if not exists "uuid-ossp";

-- AI usage table — tracks every AI request for rate limiting and analytics
create table if not exists public.ai_usage (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null,
  model_id text not null,
  provider text not null default 'freellmapi',
  input_tokens integer not null default 0,
  output_tokens integer not null default 0,
  total_tokens integer not null default 0,
  credits_consumed numeric not null default 0,
  success boolean not null default true,
  latency_ms integer not null default 0,
  created_at timestamptz not null default now()
);

-- Indexes for fast rate-limit queries
create index if not exists idx_ai_usage_user_id on public.ai_usage(user_id);
create index if not exists idx_ai_usage_user_created on public.ai_usage(user_id, created_at desc);
create index if not exists idx_ai_usage_created_at on public.ai_usage(created_at);

-- Row Level Security
alter table public.ai_usage enable row level security;

-- Users can only see their own usage
create policy "Users can view own AI usage"
  on public.ai_usage for select
  using (auth.uid() = user_id);

-- Users cannot insert/update/delete their own usage directly
-- (only the Edge Function with service role key can do this)
revoke insert, update, delete on public.ai_usage from anon, authenticated;

-- Ensure user_profiles table exists (for tier-based rate limits)
create table if not exists public.user_profiles (
  id uuid primary key default uuid_generate_v4(),
  email text unique,
  full_name text,
  subscription_tier text not null default 'free',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- RLS on user_profiles
alter table public.user_profiles enable row level security;

create policy "Users can view own profile"
  on public.user_profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.user_profiles for update
  using (auth.uid() = id);

-- Auto-create user profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.user_profiles (id, email, full_name)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
