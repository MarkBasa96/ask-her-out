# ask-her-out

One HTML file that asks someone on a date. The No button doesn't want to be clicked.

**Live:** https://markbasa96.github.io/ask-her-out/

## What it does

A card sits on a dark, twinkling sky with a photo and two buttons.

**The No button runs away.** It watches the cursor and jumps the moment you get within 50 pixels, staying inside a 100px radius of where it started and clamped to the viewport so it can't escape off-screen. If you somehow catch it, you get a "Pretty please, yes?" photo instead — and clicking that turns the No button into a second Yes and switches the dodging off. There is no way to say no. That's deliberate.

**Yes opens the planner.** The question disappears and a small form takes over: a date picker, a time picker, an email field, and an optional message box. The Confirm button only shows up once the date, time and email are all filled in.

**Confirming does three things.** A modal reads the date back in full, the details POST to a Formspree endpoint so the answer lands in my inbox, and a prefilled Google Calendar event opens in a new tab — one hour, titled "Our Date", with me added as a guest.

**The background is doing a lot.** Three layers of twinkling stars, a shooting star every few seconds, and confetti, floating hearts and falling petals when you say yes. Music starts at the same moment from a hidden YouTube player, with a mute button in the corner for anyone caught with the volume up.

## Tech

A single HTML file. Plain CSS and JavaScript, no frameworks, no build step, nothing to install — open the file and it runs. The only outside pieces are Formspree for the form and the YouTube IFrame API for the music. Responsive down to phone widths.

## An honest note

I built this to ask someone out. It's the second thing I ever shipped, and it isn't pretending to be a portfolio piece — there's no test suite, my debug `console.log`s are still in the JavaScript, and a good third of the code exists to stop one button from ever being clicked. It works, it's responsive, and it asked the question. That's the whole review.
