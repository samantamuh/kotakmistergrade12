-- Kearifan Lokal XII — Supabase setup
-- Jalankan sekali di Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  session_code text unique not null,
  teacher_name text not null,
  current_stage int not null default 1,
  timer_seconds int not null default 2400,
  timer_running boolean not null default false,
  timer_started_at timestamptz,
  timer_paused_at timestamptz,
  broadcast_message text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  name text not null,
  class_name text not null,
  current_stage int not null default 1,
  progress int not null default 0,
  status text not null default 'online',
  joined_at timestamptz not null default now(),
  last_seen timestamptz not null default now()
);

create table if not exists public.answers (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  stage int not null,
  answer text,
  score int,
  submitted_at timestamptz not null default now()
);

create table if not exists public.reflections (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  content text,
  submitted_at timestamptz not null default now()
);

alter table public.sessions enable row level security;
alter table public.students enable row level security;
alter table public.answers enable row level security;
alter table public.reflections enable row level security;

drop policy if exists sessions_public on public.sessions;
create policy sessions_public on public.sessions for all to anon, authenticated using (true) with check (true);

drop policy if exists students_public on public.students;
create policy students_public on public.students for all to anon, authenticated using (true) with check (true);

drop policy if exists answers_public on public.answers;
create policy answers_public on public.answers for all to anon, authenticated using (true) with check (true);

drop policy if exists reflections_public on public.reflections;
create policy reflections_public on public.reflections for all to anon, authenticated using (true) with check (true);

alter table public.sessions replica identity full;
alter table public.students replica identity full;
alter table public.answers replica identity full;
alter table public.reflections replica identity full;

-- Realtime publication. If a table is already a member, Supabase may report a harmless duplicate error;
-- in that case leave the existing membership enabled.
alter publication supabase_realtime add table public.sessions;
alter publication supabase_realtime add table public.students;
alter publication supabase_realtime add table public.answers;
alter publication supabase_realtime add table public.reflections;
