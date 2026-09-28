-- Date pages: the public "make your own" version.
-- Every table has Row Level Security. The page itself only ever uses the public (publishable/anon) key.
-- Never put the service_role key in this repo.

-- ---------- Admins (can hide pages and read reports) ----------
create table public.admins (
  email text primary key check (email = lower(email))
);
alter table public.admins enable row level security;
-- No policies: nobody can read or change this table through the API. Manage it with SQL.

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.admins a where a.email = lower(coalesce(auth.jwt() ->> 'email', '')));
$$;

-- ---------- Pages ----------
create table public.pages (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null check (slug ~ '^[a-z0-9](?:[a-z0-9-]{1,38})[a-z0-9]$'),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  sender_name text not null check (char_length(sender_name) between 1 and 40),
  pet_name text not null default 'love' check (char_length(pet_name) between 1 and 24),
  role text not null default 'partner' check (role in ('boyfriend', 'girlfriend', 'partner')),
  headline text not null default 'Can I steal you for a date, love?' check (char_length(headline) between 1 and 90),
  lead text not null default 'You already have my heart. Now I''d like your calendar.' check (char_length(lead) <= 160),
  card_title text check (char_length(card_title) <= 90),
  card_body text check (char_length(card_body) <= 400),
  photo_path text check (char_length(photo_path) <= 200),
  song_id text check (song_id ~ '^[A-Za-z0-9_-]{11}$'),
  calendar_email text check (calendar_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  cat_lines jsonb check (cat_lines is null or jsonb_typeof(cat_lines) = 'array'),
  hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index pages_owner_idx on public.pages (owner_id);
alter table public.pages enable row level security;

-- Anyone can read a page that isn't hidden (that's how the link works)
create policy "pages are public unless hidden" on public.pages for select
  using (not hidden or owner_id = (select auth.uid()) or (select public.is_admin()));
create policy "owners insert pages" on public.pages for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy "owners and admins update pages" on public.pages for update to authenticated
  using (owner_id = (select auth.uid()) or (select public.is_admin()))
  with check (owner_id = (select auth.uid()) or (select public.is_admin()));
create policy "owners delete pages" on public.pages for delete to authenticated
  using (owner_id = (select auth.uid()));

-- Visitors don't need to see who owns a page
revoke select on public.pages from anon;
grant select (id, slug, sender_name, pet_name, role, headline, lead, card_title, card_body, photo_path, song_id, calendar_email, cat_lines, hidden)
  on public.pages to anon;

-- Max 5 pages per account; only admins can hide/unhide; owner can't be changed
create or replace function public.pages_guard()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if (select count(*) from public.pages p where p.owner_id = new.owner_id) >= 5 then
      raise exception 'page_limit: you can have up to 5 pages' using errcode = 'P0001';
    end if;
    if new.hidden and not public.is_admin() then new.hidden := false; end if;
  else
    new.owner_id := old.owner_id;
    new.created_at := old.created_at;
    if new.hidden is distinct from old.hidden and not public.is_admin() then
      raise exception 'only an admin can hide or unhide a page' using errcode = 'P0001';
    end if;
    new.updated_at := now();
  end if;
  return new;
end;
$$;
create trigger pages_guard before insert or update on public.pages
  for each row execute function public.pages_guard();

-- ---------- Answers ----------
create table public.answers (
  id uuid primary key default gen_random_uuid(),
  page_id uuid not null references public.pages(id) on delete cascade,
  day date not null,
  time text not null check (time ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'),
  starts_at timestamptz,
  plan text not null check (char_length(plan) between 1 and 60),
  email text not null check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' and char_length(email) <= 200),
  note text check (char_length(note) <= 500),
  timezone text check (char_length(timezone) <= 64),
  seen_at timestamptz,
  created_at timestamptz not null default now()
);
create index answers_page_idx on public.answers (page_id, created_at desc);
alter table public.answers enable row level security;

-- Anyone can answer a visible page; only the page owner can read, mark seen or delete answers
create policy "anyone can answer a visible page" on public.answers for insert to anon, authenticated
  with check (exists (select 1 from public.pages p where p.id = page_id and not p.hidden));
create policy "owners read answers" on public.answers for select to authenticated
  using (exists (select 1 from public.pages p where p.id = page_id and p.owner_id = (select auth.uid())));
create policy "owners mark answers seen" on public.answers for update to authenticated
  using (exists (select 1 from public.pages p where p.id = page_id and p.owner_id = (select auth.uid())));
create policy "owners delete answers" on public.answers for delete to authenticated
  using (exists (select 1 from public.pages p where p.id = page_id and p.owner_id = (select auth.uid())));

revoke update on public.answers from anon, authenticated;
grant update (seen_at) on public.answers to authenticated;

-- Rate limit: at most 10 answers per page per hour
create or replace function public.answers_rate_limit()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if (select count(*) from public.answers a where a.page_id = new.page_id and a.created_at > now() - interval '1 hour') >= 10 then
    raise exception 'rate_limit: too many answers for this page, try again later' using errcode = 'P0001';
  end if;
  new.seen_at := null;
  new.created_at := now();
  return new;
end;
$$;
create trigger answers_rate_limit before insert on public.answers
  for each row execute function public.answers_rate_limit();

-- ---------- Reports ----------
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  page_id uuid not null references public.pages(id) on delete cascade,
  reason text not null check (char_length(reason) between 1 and 500),
  resolved boolean not null default false,
  created_at timestamptz not null default now()
);
create index reports_page_idx on public.reports (page_id);
alter table public.reports enable row level security;

create policy "anyone can report a page" on public.reports for insert to anon, authenticated
  with check (exists (select 1 from public.pages p where p.id = page_id));
create policy "admins read reports" on public.reports for select to authenticated
  using ((select public.is_admin()));
create policy "admins resolve reports" on public.reports for update to authenticated
  using ((select public.is_admin()));

-- Rate limit: at most 20 reports per page per hour
create or replace function public.reports_rate_limit()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if (select count(*) from public.reports r where r.page_id = new.page_id and r.created_at > now() - interval '1 hour') >= 20 then
    raise exception 'rate_limit: this page was reported a lot already' using errcode = 'P0001';
  end if;
  new.resolved := false;
  new.created_at := now();
  return new;
end;
$$;
create trigger reports_rate_limit before insert on public.reports
  for each row execute function public.reports_rate_limit();

-- Triggers run as their owner, but nobody should call them directly
revoke execute on function public.pages_guard() from public, anon, authenticated;
revoke execute on function public.answers_rate_limit() from public, anon, authenticated;
revoke execute on function public.reports_rate_limit() from public, anon, authenticated;

-- ---------- Photos ----------
-- Public read; JPG/PNG/WebP up to 2 MB; each user writes only inside a folder named after their user id
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', true, 2097152, array['image/jpeg', 'image/png', 'image/webp']);

create policy "owners upload photos" on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "owners see own photos" on storage.objects for select to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "owners replace photos" on storage.objects for update to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "owners delete photos" on storage.objects for delete to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = (select auth.uid())::text);
