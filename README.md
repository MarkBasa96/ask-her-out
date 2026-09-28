# ask-her-out

One HTML file that asks my girlfriend on a date. The No button doesn't want to be clicked.

**Live:** https://markbasa96.github.io/ask-her-out/

## What it does

A question sits under a moving night sky: "Can I steal you for a date, love?", with a Yes button, a No button, and a card for the hopeless romantic asking (me, in the black coat).

**The sky is alive.** Three layers of drifting, twinkling stars and a faint Milky Way band. Shooting stars every second or two, a bigger comet with a sparkling tail every few seconds, and every so often a group of stars joins up into a heart and fades. Slow purple and pink clouds drift behind everything, and embers float up from a sunset glow that rises when the page opens. Moving the mouse shifts the stars a little, and tapping the sky bursts out sparkles and hearts.

**A pixel cat wanders around.** It walks anywhere on the screen, sometimes behind the words and sometimes in front of them. Now and then it stops, sits, and says something sweet in a speech bubble: "psst… he's still crazy about you", "10/10 boyfriend. would recommend." Tap it and it talks. After she says yes, it switches to celebrating.

**The No button runs away.** It jumps when the mouse gets close, and on phones the first taps make it run instead of counting. Every escape makes Yes a bit bigger, No a bit smaller, and No says something new ("Are you sure, babe? 🥺"). After nine tries it gets tired. If she catches it, a glass pop-up with a kitten holding a heart asks her to reconsider.

**Yes opens the planner.** Confetti, the music starts, and a frosted-glass pop-up slides in: tappable day cards for the next three weeks, what we're doing (coffee, dinner, a movie, or a surprise), a time, her email and an optional note. The button tells her what's still missing instead of hiding.

**Confirming gives her a ticket.** A glass "Admit Two" date ticket with the date, time, plan and her note. Her answer is sent to my inbox through Formspree, and the page only says "Sent to Mark" once it actually arrived. There's an Add to Google Calendar button (with me as a guest) and a Save for iPhone / Outlook button that downloads a calendar file.

**Sharing the link looks nice.** Messenger, IG and the like show a preview card with the sunset and the question instead of a bare URL.

## Tech

A single HTML file: plain CSS and JavaScript, no frameworks, no build step, nothing to install. The sky is drawn on a canvas; the cat is a 20×14 pixel sprite drawn in code. The only outside pieces are Google Fonts, Formspree for the answer, and the YouTube IFrame API for the music. It works on phones, respects "reduce motion" (the sky and cat hold still), and the pop-ups work with a keyboard.

## History

The first version was the second thing I ever shipped: a white card, a No button that dodged the mouse, and a lot of `console.log`s. The rebuild keeps the idea and fixes what the first one got wrong. The calendar invite used to land at the wrong time (7 PM showed up as 11 AM in the Philippines), the date could show a day early in the Americas, and on phones she could simply tap No.
