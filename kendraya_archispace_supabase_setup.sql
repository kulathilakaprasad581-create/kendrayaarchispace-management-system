-- KENDRAYA ARCHISPACE - SUPABASE SETUP
-- Run this in Supabase Dashboard > SQL Editor.

create table if not exists public.app_state (
  id uuid primary key references auth.users(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.app_state enable row level security;

create policy "Users can read their own ArchiSpace state"
on public.app_state for select
to authenticated
using (auth.uid() = user_id);

create policy "Users can insert their own ArchiSpace state"
on public.app_state for insert
to authenticated
with check (auth.uid() = user_id);

create policy "Users can update their own ArchiSpace state"
on public.app_state for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Private storage bucket for drawings, PDFs and project cover images.
insert into storage.buckets (id, name, public)
values ('kendraya-files', 'kendraya-files', false)
on conflict (id) do update set public = false;

-- Each uploaded object is stored under: <authenticated-user-id>/<filename>
create policy "Users can upload their own ArchiSpace files"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'kendraya-files'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can read their own ArchiSpace files"
on storage.objects for select
to authenticated
using (
  bucket_id = 'kendraya-files'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can update their own ArchiSpace files"
on storage.objects for update
to authenticated
using (
  bucket_id = 'kendraya-files'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'kendraya-files'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can delete their own ArchiSpace files"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'kendraya-files'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Optional: make email confirmation easier while testing.
-- In Supabase Dashboard > Authentication > Providers > Email,
-- you can disable email confirmation if you want immediate login.
