# CLAUDE.md

Context for Claude Code when working in this repo. Read this first, then `docs/`.

## What this is

Two things share this repo:

1. **Mark's page.** A single-page website Mark (Joemark, GitHub `MarkBasa96`) sends to his girlfriend to ask her on a date. It lives at https://markbasa96.github.io/ask-her-out/ (GitHub Pages, served from `main`). `index.html` only redirects to `ask-her-out.html`. **It must keep working exactly as it is.** It's **private to Mark**: never link it from the README or any public-facing page (screenshots are fine), and it isn't served on Vercel.
2. **The public builder** (built 2026-09-28). Anyone signs in with a magic link, fills in a form and gets `https://ask-her-out-orpin-psi.vercel.app/p/<slug>`. That link is the same `ask-her-out.html`, loading their words from Supabase. Hosted on Vercel from `main`; data in Supabase. See `docs/2026-09-28-builder.md`.

She is already his girlfriend. All wording is written for someone **already in a relationship**, e.g. "Can I steal you for a date, love?" and never "will you go out with me". Keep it that way.

## Files

| Path | What it is |
|---|---|
| `ask-her-out.html` | The date page: HTML, CSS and JS in one file, no build step. Mark's page by default; a builder page with `/p/<slug>`, `?p=<slug>` or `?preview=1` |
| `index.html` | Redirect to `ask-her-out.html`, plus link-preview (Open Graph) tags |
| `create.html` | Builder: magic-link sign-in, form, live preview iframe, photo shrink + upload, slug check, publish/edit (`?edit=<id>`) |
| `dashboard.html` | A creator's pages and answers (tickets, Google Calendar/.ics), marks answers seen, delete; **Admin** tab for admins: **All pages** (counts, search, every page on the site with Open and Hide/Unhide) and **Reported pages**. Admins can read every page but never other people's answers (RLS). The Admin tab is Mark's only: don't document it in the README |
| `site.css`, `site.js` | Shared by `create.html`/`dashboard.html`: tokens and glass styles; Supabase client, sign-in card, nav user menu, `pageLink()`, `friendlyError()` |
| `vercel.json` | Redirects (applied before files): `/` and `/index.html` → `/create.html`, and `/ask-her-out.html` without `?p=`/`?preview=` → `/create.html`, so Mark's page isn't on Vercel. Rewrites: `/p/Pics/:file` → `/Pics/:file`, `/p/:slug` → `/ask-her-out.html` |
| `supabase/migrations/` | `0001_init.sql` (schema, RLS, triggers, `photos` bucket), `0002_seed_admin.sql` (Mark's email as admin) and `0003_slideshow_and_changes.sql` (`pages.photo_paths`, `answers.replaces`). All applied |
| `Pics/icon.svg` | The logo: a heart rising out of the sunset arc. Favicon and top-bar mark on every page (`icon-32.png`, `apple-touch-icon.png` are PNG fallbacks) |
| `Pics/mark.jpg` | Mark's photo (black coat) on the "hopeless romantic" card |
| `Pics/cat-heart.jpg` | Kitten holding a heart: the "pretty please" pop-up |
| `Pics/cat-chef.jpg` | Chef cat ("Today's menu: love and care"): top of the planner |
| `Pics/cat-kiss.jpg` | Two cats kissing: top of the date ticket |
| `Pics/cat-hearts.jpg` | Heart-eyes cat: the stamp on the ticket |
| `Pics/cat-picnic.jpg` | Two cats having a picnic ("us ?"): the "see you" state after the date is set (builder pages) |
| `Pics/og.jpg` | 1200×630 link-preview image (a screenshot of the hero) |
| `docs/2026-09-28-rebuild.md` | The rebuild of Mark's page (first session on 2026-09-28) |
| `docs/2026-09-28-builder.md` | The builder (second session): decisions, tests, **Mark's to-do list**, and the later additions (slideshow, other date, "see you") |
| `docs/supabase-vercel-plan.md` | The original plan for the builder, with the open questions answered |
| `docs/screenshots/` | Screenshots used in the README (builder, dashboard, a made page, mockups, logo) |

The cat pictures are small (~170–235px), so they're only ever shown as small "sticker" cards. Don't display them large.

## How `ask-her-out.html` is organised

The script is one IIFE, in this order:

1. **`CONFIG`**: name, email, Formspree URL, YouTube song ID and photo. All personal data lives here; `[data-name]` elements get the name filled in.
   **Builder loader** (right after `CONFIG`; the IIFE is `async` for this): `SLUG`/`PREVIEW` from the URL. Only if one is set does it `await loadPage()` (plain `fetch` to PostgREST with the publishable key, or `localStorage['dp-preview']` in preview) and call `applyPage()`, which swaps the headline, lead, card, photo, pet name, role wording, title, and adds the footer (Make your own / Report) and `#reportModal`. With 2+ photos (`photo_urls`, from `photo_paths`) `slideshow()` crossfades them every 4.2s (tap/swipe/dots). No row → `pageMissing()`. With no slug, `PAGE` is `null` and every line below behaves exactly as for Mark. Builder pages save answers with `saveAnswer()` (Supabase `answers`) instead of `sendToMark()` (Formspree), and use name-based cat lines (`MARK_CAT_LINES` are Mark's).
2. **Sky**: a canvas with drifting, twinkling stars, a Milky Way band, shooting stars (every 0.9–2.6s), comets (every 7–11s), a heart constellation (every 11–16s), embers, parallax on pointer move, and sparkles when the sky is tapped. Nebula clouds and the rising sunset arc are CSS.
3. **Music**: YouTube IFrame API with a hidden player. While the welcome is up (`welcoming`), `onReady` only gets ready; tapping **Open it** calls `playMusic()` inside the tap, so it starts with sound from the top. Without the welcome (preview), `onReady` plays with sound and waits (up to 2.5s, or 8s while buffering) for it to really start before deciding sound was blocked; only then it plays muted and unmutes on the first `pointerdown`/`pointerup`/`touchend`/`click`/`keydown` (phones only grant sound on some of those), stopping once it's audible (`gotSound()`). It loops, and the nav has a speaker icon to mute and unmute (`#musicBtn`, `.on` class when audible). **Fullscreen:** F toggles it (not with Ctrl/Cmd, not while typing).
4. **Modals**: glass pop-ups (`.modal` > `.panel`) with `openModal(id)`/`closeModal(el)`, Escape to close, and a focus trap.
5. **No button**: dodges the mouse by proximity, and on touch the tap makes it run instead of registering. It **never gives up** (Mark asked for this explicitly). Each dodge grows Yes, shrinks No and shows a line from `NO_LINES`. There's a 260ms cooldown between dodges. The pretty-please pop-up only appears if No is actually clicked, which now only happens via the keyboard.
6. **Yes flow**: `sayYes()` starts the music, fires confetti and hearts, then opens the planner.
7. **Planner**: day chips for the next 21 days (builder pages add an **Other date** chip with `#otherDay`, a date field), plan tiles, time chips (+ "Other" time input), email and note. The submit button text says what's missing.
8. **Sending + calendar**: Formspree POST with `Accept: application/json`, checks `res.ok` and shows retry on failure. Builder pages send a client-made `id` (anon can't read answers back) and `replaces` when changing a date.
   **"See you" (builder pages only):** dates that reached Supabase are kept in `localStorage['dp-dates:<page id>']` (`DATES`). When the ticket closes (`afterTicket()`), or on reload, `renderSet()` swaps the question for "See you soon, <pet>", a countdown, the picnic cats and one row per date with **Ticket** and **Change**, plus **Add another date** (`openPlanner()`). Mark's page never does this. Google Calendar link uses **local** times plus `ctz=<her timezone>`. `.ics` download uses UTC `Z` times.
9. **Stats count-up** when the card scrolls into view.
10. **Pixel cat**: a 20×14 sprite drawn from string arrays (`SPRITES`: walkA, walkB, sit, blink, tail, plus wave1/wave2/lick1/lick2 made with `patch()` edits of sit/blink) onto a canvas scaled with `image-rendering: pixelated`. It's a state machine: it walks to random points (sometimes "zoomies"), then sits for 3–6s and says a random line from `CAT_LINES` (before yes) or `CAT_AFTER_LINES` (after yes). On a computer (`ON_PC`: hover + fine pointer, not the preview) both include "on a computer? press F for fullscreen ✨", and it says it once after its hello. Mark asked for this on 2026-09-28, on his page too. It's **always on top of everything** (`z-index 70`, pop-ups are 50) with `pointer-events: none`, so taps go through it; a capture `click` listener checks whether a tap landed on it and makes it talk (`poke()`). The speech bubble `#bubble` (`z-index 71`) is a separate fixed element. Mark asked for the cat on top on 2026-09-28; before that it switched between behind and in front of the text.
11. **Welcome** (end of the script): `body.welcoming` blurs `.nav`/`main` (and makes them `inert`) behind `#welcome`. The big cat is `cat.welcomeShow(canvas, says)`: every 160ms it composes a frame from a tail (`sit`/`tail`, left 8 columns, wiggling) and a body (wave, blink, lick, idle), with a matching speech line. **Open it** → `playMusic()`, remove the blur, `cat.arrive()` (the small cat starts at the bottom centre and says hi). The builder's preview (`?preview=1`, `html.no-welcome`) skips it.

## Things that were bugs before. Don't reintroduce them

- **Calendar time:** don't build Google Calendar dates with `toISOString()` and then strip the `Z`. That turned 7 PM in Manila into 11 AM. Use local stamps plus `ctz`, or real UTC stamps that keep the `Z`.
- **Dates from strings:** don't use `new Date('YYYY-MM-DD')`, because it parses as UTC and shows the previous day in the Americas. Build dates from parts with `new Date(y, m - 1, d, h, min)`.
- **Autoplay:** browsers block sound until a user gesture. That's what the welcome's **Open it** tap is for; keep it, and keep the muted-then-unmute-on-first-tap fallback for when there's no welcome.
- **Muting a song that's just loading:** the old code checked once after 1.2s and muted anything not yet `PLAYING`, which muted songs that were only buffering even when sound was allowed. Wait for `PLAYING`, and treat `BUFFERING` as "not decided yet".
- **Pointer events:** `main` has `pointer-events: none` with `main > * { pointer-events: auto }` so the cat can be tapped in the empty areas when it's behind the text.
- **Mark's page must not change:** don't add wrapper `<span>`s inside `.btn` or `.badge` (they're flex with `gap`, so spans add visible space). Custom wording for builder pages is set in `applyPage()` instead. After touching `ask-her-out.html`, compare it against the previous commit with no slug (text, the ticket, the Google Calendar link, and a screenshot).
- **Pronouns on builder pages:** use the creator's name, not "he"/"they" (verb agreement). Mark's lines keep "he".
- **Vercel serves real files before rewrites.** A rewrite of `/` never ran because `index.html` exists (it forwards to Mark's page for GitHub Pages), so the builder link opened Mark's page. `/` → `/create.html` is a **redirect**, which Vercel applies before files. A rewrite only works for paths with no file behind them, like `/p/<slug>`. Test servers must do the same: files first, then rewrites.
- **Relative paths under `/p/`:** `/p/<slug>` is one folder deep, so `Pics/...` is rewritten in `vercel.json`; links built in JS use `ROOT`.
- **Supabase columns:** `anon` has column-level `select` on `pages` (no `owner_id`), so select named columns, never `*`, from the date page.

## Supabase and Vercel

- **Supabase project `ask-her-out`**, ref `xrjkwjcftuthdgdebxwg`, URL `https://xrjkwjcftuthdgdebxwg.supabase.co`, org "Joe's Apps" (free plan). The **publishable** key (`sb_publishable_…`) is in `site.js` and `ask-her-out.html`; it's public by design. **Never commit the `service_role`/secret key**, and never put it in any file here.
- Tables: `pages`, `answers`, `reports`, `admins`. All have RLS. Triggers: `pages_guard` (5 pages per owner, admin-only `hidden`, owner can't change), `answers_rate_limit` (10 per page per hour), `reports_rate_limit` (20 per page per hour). `is_admin()` checks the JWT email against `admins`. Storage bucket `photos`: public read, 2 MB, JPG/PNG/WebP, write only into `<user id>/`.
- Schema changes: add a new numbered file in `supabase/migrations/` **and** apply it with the Supabase connector (`apply_migration`), then run `get_advisors`. Test RLS with a SQL block that switches roles and ends with `raise exception` so it rolls back (see the builder doc).
- **Vercel project `ask-her-out`** (`prj_DuFU9wm2ymIfNhoNI0GusaaBVVPv`) in team "Jarvis" (`team_2ZBlZnJJuxrIz5WWQXfH3pxt`), linked to this repo. Production = `main` at `ask-her-out-orpin-psi.vercel.app`; every branch push gets a protected preview.
- **Don't touch `gastos`.** Mark has a Supabase project and a Vercel project with that name for a different app.
- Mark has done the dashboard-only setup (Auth URL configuration, custom SMTP via Gmail app password, email rate limit 30/h, signed in as admin). **Public vs private:** the public (README, Vercel) gets only the builder and dashboard. Mark's own page and the Admin tab are his; his admin notes are kept outside the repo.

## Conventions

- Plain HTML/CSS/JS, no frameworks, no build step. Mark's page stays one self-contained HTML file; the builder pages share `site.css`/`site.js`.
- Respect `prefers-reduced-motion`: the sky draws one still frame, and the cat sits in a corner and still talks.
- Design tokens are at the top of the CSS (`--sun` gradient orange→pink, near-black `--bg`, glass surfaces). The look is inspired by a dark "Redsun" landing page Mark shared: black background, glowing eclipse arc, frosted glass. It's blended with the original pink night-sky theme.
- Mark likes to see a mockup or preview video before big visual changes, and gives the go-ahead himself.

## Testing

There's no test suite. Check changes in a real browser at phone (390×844) and laptop (1280×800) sizes. Go through the whole flow: No dodges, Yes, the planner, submit, then the ticket. Confirm the ticket time and the Google Calendar `dates=` match what was picked, with `ctz` set. Mock Formspree when testing so it doesn't email Mark.

For the builder, test both `/p/<slug>` (answers go to Supabase, not Formspree) and Mark's page with no slug (unchanged). Serve the repo the way Vercel does (a tiny Node server is enough): **redirects first, then real files, then rewrites**, because `/p/...` paths only work that way and because a rewrite never beats a real file. Test Mark's page on a plain static server (like GitHub Pages), since Vercel redirects it to the builder. The cloud sandbox can't reach Supabase, jsDelivr or YouTube, so mock them with Playwright `page.route`: seed a fake session in `localStorage['sb-xrjkwjcftuthdgdebxwg-auth-token']` for the builder and dashboard, and use a fake `YT.Player` for the music (blocked until a real gesture). The `.svg` content type matters for the logo. Use the Supabase connector for real database checks.

## Picking this up on another machine

Mark has an older local copy of this repo. Start by pulling `main` (`git pull origin main`) so the local copy matches GitHub, then read this file and `docs/`. The builder is built; ideas for what's next are at the end of `docs/2026-09-28-builder.md` (per-page link previews, email notifications).
