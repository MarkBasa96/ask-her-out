# CLAUDE.md

Context for Claude Code when working in this repo. Read this first, then `docs/`.

## What this is

A single-page website Mark (Joemark, GitHub `MarkBasa96`) sends to his girlfriend to ask her on a date. It lives at https://markbasa96.github.io/ask-her-out/ (GitHub Pages, served from `main`). `index.html` only redirects to `ask-her-out.html`.

She is already his girlfriend. All wording is written for someone **already in a relationship**, e.g. "Can I steal you for a date, love?" and never "will you go out with me". Keep it that way.

## Files

| Path | What it is |
|---|---|
| `ask-her-out.html` | The whole site: HTML, CSS and JS in one file, no build step |
| `index.html` | Redirect to `ask-her-out.html`, plus link-preview (Open Graph) tags |
| `Pics/mark.jpg` | Mark's photo (black coat) on the "hopeless romantic" card |
| `Pics/cat-heart.jpg` | Kitten holding a heart: the "pretty please" pop-up |
| `Pics/cat-chef.jpg` | Chef cat ("Today's menu: love and care"): top of the planner |
| `Pics/cat-kiss.jpg` | Two cats kissing: top of the date ticket |
| `Pics/cat-hearts.jpg` | Heart-eyes cat: the stamp on the ticket |
| `Pics/og.jpg` | 1200×630 link-preview image (a screenshot of the hero) |
| `docs/2026-09-28-rebuild.md` | What was built on 2026-09-28 and why |
| `docs/supabase-vercel-plan.md` | Plan for the public "make your own page" version (not built yet) |

The cat pictures are small (~170–235px), so they're only ever shown as small "sticker" cards. Don't display them large.

## How `ask-her-out.html` is organised

The script is one IIFE, in this order:

1. **`CONFIG`**: name, email, Formspree URL, YouTube song ID and photo. All personal data lives here; `[data-name]` elements get the name filled in.
2. **Sky**: a canvas with drifting, twinkling stars, a Milky Way band, shooting stars (every 0.9–2.6s), comets (every 7–11s), a heart constellation (every 11–16s), embers, parallax on pointer move, and sparkles when the sky is tapped. Nebula clouds and the rising sunset arc are CSS.
3. **Music**: YouTube IFrame API with a hidden player. It autoplays on load. If the browser blocks sound it plays muted and unmutes on the first `pointerdown`/`keydown` (except on the mute button itself). It loops, and the nav has a speaker icon to mute and unmute (`#musicBtn`, `.on` class when audible).
4. **Modals**: glass pop-ups (`.modal` > `.panel`) with `openModal(id)`/`closeModal(el)`, Escape to close, and a focus trap.
5. **No button**: dodges the mouse by proximity, and on touch the tap makes it run instead of registering. It **never gives up** (Mark asked for this explicitly). Each dodge grows Yes, shrinks No and shows a line from `NO_LINES`. There's a 260ms cooldown between dodges. The pretty-please pop-up only appears if No is actually clicked, which now only happens via the keyboard.
6. **Yes flow**: `sayYes()` starts the music, fires confetti and hearts, then opens the planner.
7. **Planner**: day chips for the next 21 days, plan tiles, time chips (+ "Other" time input), email and note. The submit button text says what's missing.
8. **Sending + calendar**: Formspree POST with `Accept: application/json`, checks `res.ok` and shows retry on failure. Google Calendar link uses **local** times plus `ctz=<her timezone>`. `.ics` download uses UTC `Z` times.
9. **Stats count-up** when the card scrolls into view.
10. **Pixel cat**: a 20×14 sprite drawn from string arrays (`SPRITES`: walkA, walkB, sit, blink, tail) onto a canvas scaled with `image-rendering: pixelated`. It's a state machine: it walks to random points (sometimes "zoomies"), then sits for 3–6s and says a random line from `CAT_LINES` (before yes) or `CAT_AFTER_LINES` (after yes). It randomly switches between behind the text (`z-index 5`) and in front (`.front`, `z-index 26`, `pointer-events: none` so it never blocks buttons). The speech bubble `#bubble` is a separate fixed element on top so it stays readable when the cat is behind the card. Tap the cat to make it talk.

## Things that were bugs before. Don't reintroduce them

- **Calendar time:** don't build Google Calendar dates with `toISOString()` and then strip the `Z`. That turned 7 PM in Manila into 11 AM. Use local stamps plus `ctz`, or real UTC stamps that keep the `Z`.
- **Dates from strings:** don't use `new Date('YYYY-MM-DD')`, because it parses as UTC and shows the previous day in the Americas. Build dates from parts with `new Date(y, m - 1, d, h, min)`.
- **Autoplay:** browsers block sound until a user gesture, so keep the muted-then-unmute-on-first-tap fallback.
- **Pointer events:** `main` has `pointer-events: none` with `main > * { pointer-events: auto }` so the cat can be tapped in the empty areas when it's behind the text.

## Conventions

- Keep it one HTML file, plain CSS/JS, no frameworks, no build step (unless the Supabase/Vercel version needs one; see the plan).
- Respect `prefers-reduced-motion`: the sky draws one still frame, and the cat sits in a corner and still talks.
- Design tokens are at the top of the CSS (`--sun` gradient orange→pink, near-black `--bg`, glass surfaces). The look is inspired by a dark "Redsun" landing page Mark shared: black background, glowing eclipse arc, frosted glass. It's blended with the original pink night-sky theme.
- Mark likes to see a mockup or preview video before big visual changes, and gives the go-ahead himself.

## Testing

There's no test suite. Check changes in a real browser at phone (390×844) and laptop (1280×800) sizes. Go through the whole flow: No dodges, Yes, the planner, submit, then the ticket. Confirm the ticket time and the Google Calendar `dates=` match what was picked, with `ctz` set. Mock Formspree when testing so it doesn't email Mark.

## Picking this up on another machine

Mark has an older local copy of this repo. Start by pulling `main` (`git pull origin main`) so the local copy matches GitHub, then read this file and `docs/`. The next planned piece of work is `docs/supabase-vercel-plan.md`. It needs the Supabase and Vercel accounts connected first, and nothing in it has been built yet.
