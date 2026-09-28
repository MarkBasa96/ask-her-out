# Plan: a public "make your own date page" version (Supabase + Vercel)

Status: **built on 2026-09-28** (see [`2026-09-28-builder.md`](2026-09-28-builder.md) for what was built, what differs from this plan, and Mark's remaining to-dos). This is the original plan, kept for reference.

## Goal

- **Mark's own page stays his.** It keeps working exactly as it does now, with his `CONFIG`, photos and Formspree.
- **Anyone else can make their own page.** Two ways:
  1. **Copy the repo** (fork or download), edit `CONFIG` and `Pics/`, and host it themselves. This already works; see the README.
  2. **Use the live builder** (this plan): sign in, fill in a form (names, photo, headline, message, song), and get a link like `https://<site>/p/<slug>` to send to their partner. Answers are saved in Supabase and emailed to the creator.

## Architecture

- **Vercel** hosts the static site from this GitHub repo. It deploys automatically on every push to `main` and needs no build step.
- **Supabase** provides:
  - **Auth:** magic-link email sign-in for creators.
  - **Postgres:** a `pages` table for each creator's page config and an `answers` table for what their partner picked.
  - **Storage:** a public `photos` bucket for creators' photos.
  - **Edge Function:** emails the creator when an answer arrives. Optional, since the creator can also just check their dashboard.
- The page script checks the URL:
  - with no `?p=`/`/p/<slug>`, it uses the built-in `CONFIG` (Mark's page);
  - with a slug, it fetches that row from `pages` using the public anon key and overrides `CONFIG` and the wording.
- The Supabase **anon key is public by design** and is safe to put in the HTML, because Row Level Security protects the data. **Never** commit the `service_role` key.

## Proposed files

| File | Purpose |
|---|---|
| `ask-her-out.html` | Same page. Add a small loader that reads `/p/<slug>` or `?p=` and applies that page's config from Supabase |
| `create.html` | The builder: sign in, form, photo upload, preview, "copy link" |
| `dashboard.html` | A creator's pages and the answers they received |
| `vercel.json` | Rewrite `/p/:slug` → `/ask-her-out.html` and `/` → `/ask-her-out.html` |
| `supabase/migrations/0001_init.sql` | Tables, RLS policies, storage bucket |

## Database (first migration)

```sql
create table public.pages (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null check (slug ~ '^[a-z0-9-]{3,40}$'),
  owner_id uuid not null references auth.users(id) on delete cascade,
  sender_name text not null,           -- e.g. "Mark"
  partner_name text,                   -- optional, e.g. used in "Hey Anna"
  headline text not null default 'Can I steal you for a date, love?',
  lead text not null default 'You already have my heart. Now I''d like your calendar.',
  card_title text,                     -- e.g. "Mark, still falling for you every day."
  card_body text,
  photo_path text,                     -- path in the "photos" bucket
  song_id text,                        -- YouTube video ID
  calendar_email text,                 -- creator email added as a calendar guest
  cat_lines jsonb,                     -- optional custom lines for the pixel cat
  created_at timestamptz not null default now()
);

create table public.answers (
  id uuid primary key default gen_random_uuid(),
  page_id uuid not null references public.pages(id) on delete cascade,
  day date not null,
  time text not null,
  plan text not null,
  email text not null check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  note text check (char_length(note) <= 500),
  timezone text,
  created_at timestamptz not null default now()
);

alter table public.pages enable row level security;
alter table public.answers enable row level security;

-- Anyone can read a page (that's how the link works); only the owner can change it
create policy "pages are public" on public.pages for select using (true);
create policy "owners insert pages" on public.pages for insert with check (auth.uid() = owner_id);
create policy "owners update pages" on public.pages for update using (auth.uid() = owner_id);
create policy "owners delete pages" on public.pages for delete using (auth.uid() = owner_id);

-- Anyone can answer; only the page owner can read the answers
create policy "anyone can answer" on public.answers for insert with check (true);
create policy "owners read answers" on public.answers for select
  using (exists (select 1 from public.pages p where p.id = page_id and p.owner_id = auth.uid()));

-- Photos: public read, owners write into a folder named after their user id
insert into storage.buckets (id, name, public) values ('photos', 'photos', true);
create policy "owners upload photos" on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
```

## Steps

1. **Supabase:** create a project (free tier), apply the migration, and enable email magic-link auth. Set the Site URL and redirect URLs to the Vercel domain.
2. **Vercel:** import `MarkBasa96/ask-her-out` from GitHub with Framework "Other", no build command, and the repo root as the output directory. The Vercel connector can list and inspect projects and deployments but can't create them, so the import is a one-minute step in the Vercel dashboard, unless the Vercel CLI and a token are available.
3. Add `vercel.json` rewrites.
4. Add the slug loader to `ask-her-out.html`. When a slug is present, insert answers into Supabase instead of (or as well as) Formspree.
5. Build `create.html` and `dashboard.html` in the same visual style: dark background, sunset gradient, glass panels.
6. **Optional:** add a Supabase Edge Function plus a database webhook on `answers` insert that emails the page owner (e.g. via Resend).
7. **Test:** create a page with a second account, open its link in a private window, answer, and check the answer shows only on the owner's dashboard.

## Open questions for Mark (answered 2026-09-28)

- Custom domain, or the default `*.vercel.app` one? → **Default.** It's `ask-her-out-orpin-psi.vercel.app`, because `ask-her-out.vercel.app` was taken.
- Should Mark's own page move to Vercel too, or stay on GitHub Pages? → **Stays on GitHub Pages.** On Vercel, `/` is the builder.
- Email notifications for creators, or dashboard-only to start? → **Dashboard only** for now.
- Any limits? → **All of them:** 5 pages per account; JPG/PNG/WebP photos up to 2 MB; 10 answers per page per hour; a report link on every page, and an admin (Mark) who can hide pages.

## Differences from this plan

- A **new Supabase project** `ask-her-out` was made (Mark's other project, `gastos`, is untouched).
- `pages` gained `pet_name`, `role`, `hidden` and `updated_at`; `answers` gained `starts_at` and `seen_at`; there are new `reports` and `admins` tables. Visitors can't read `owner_id`.
- `vercel.json` sends `/` to `create.html` (not to Mark's page) and adds `/p/Pics/:file` so images load under `/p/`.
- Shared `site.css` and `site.js` for the builder and dashboard.
