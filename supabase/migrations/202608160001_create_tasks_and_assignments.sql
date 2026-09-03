-- Campus To-Do: user-owned tasks and assignments.
-- Review and apply this migration manually in your Supabase project.

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  description text,
  completed boolean not null default false,
  priority text not null default 'medium'
    check (priority in ('low', 'medium', 'high')),
  category text,
  due_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.assignments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  subject text not null,
  description text,
  platform text not null default 'manual'
    check (platform in ('manual', 'vtop', 'neocolab', 'moodle', 'vitol', 'other')),
  deadline timestamptz not null,
  status text not null default 'pending'
    check (status in ('pending', 'submitted', 'overdue')),
  priority text not null default 'medium'
    check (priority in ('low', 'medium', 'high')),
  external_url text,
  source_identifier text,
  reminder_times timestamptz[] not null default array[]::timestamptz[],
  last_synced_at timestamptz
);

create index tasks_user_id_idx on public.tasks (user_id);
create index tasks_user_due_at_idx on public.tasks (user_id, due_at);
create index assignments_user_id_idx on public.assignments (user_id);
create index assignments_user_deadline_idx
  on public.assignments (user_id, deadline);

alter table public.tasks enable row level security;
alter table public.assignments enable row level security;

create policy "Users can select their own tasks"
on public.tasks
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can insert their own tasks"
on public.tasks
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can update their own tasks"
on public.tasks
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Users can delete their own tasks"
on public.tasks
for delete
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can select their own assignments"
on public.assignments
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can insert their own assignments"
on public.assignments
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can update their own assignments"
on public.assignments
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Users can delete their own assignments"
on public.assignments
for delete
to authenticated
using ((select auth.uid()) = user_id);
