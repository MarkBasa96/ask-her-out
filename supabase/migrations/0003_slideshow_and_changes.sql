-- 1. Several photos per page (they play as a slideshow on the card).
--    photo_path stays as the first photo (the cover), so the dashboard and older code keep working.
alter table public.pages add column photo_paths text[]
  check (photo_paths is null or (cardinality(photo_paths) between 1 and 10 and char_length(array_to_string(photo_paths, '|')) <= 2200));
grant select (photo_paths) on public.pages to anon;

-- 2. They can change a date they already locked in. The new answer points at the one it replaces;
--    visitors still can't read or change answers, so the page makes the id itself and sends it along.
alter table public.answers add column replaces uuid references public.answers(id) on delete set null;
create index answers_replaces_idx on public.answers (replaces);

-- Only keep "replaces" when it's an answer on the same page
create or replace function public.answers_rate_limit()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if (select count(*) from public.answers a where a.page_id = new.page_id and a.created_at > now() - interval '1 hour') >= 10 then
    raise exception 'rate_limit: too many answers for this page, try again later' using errcode = 'P0001';
  end if;
  if new.replaces is not null and not exists (select 1 from public.answers a where a.id = new.replaces and a.page_id = new.page_id) then
    new.replaces := null;
  end if;
  new.seen_at := null;
  new.created_at := now();
  return new;
end;
$$;
revoke execute on function public.answers_rate_limit() from public, anon, authenticated;
