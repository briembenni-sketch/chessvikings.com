-- Migration: create module_progress table
-- Run this in the Supabase SQL editor for the chessvikings project.
-- Supabase project: https://carjkdzmfwnutgakrahy.supabase.co

create table if not exists public.module_progress (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  module_number   smallint not null check (module_number between 1 and 8),
  completed       boolean not null default false,
  watched_percent integer not null default 0 check (watched_percent between 0 and 100),
  updated_at      timestamptz not null default now(),

  -- one row per user per module
  unique (user_id, module_number)
);

-- Automatically update updated_at on upsert
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger module_progress_updated_at
  before update on public.module_progress
  for each row execute function public.set_updated_at();

-- RLS: users can only read/write their own rows
alter table public.module_progress enable row level security;

create policy "Users can view own progress"
  on public.module_progress for select
  using (auth.uid() = user_id);

create policy "Users can upsert own progress"
  on public.module_progress for insert
  with check (auth.uid() = user_id);

create policy "Users can update own progress"
  on public.module_progress for update
  using (auth.uid() = user_id);
