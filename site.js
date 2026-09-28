/* Shared code for the builder (create.html) and dashboard (dashboard.html).
   Loads after supabase-js (from the jsDelivr CDN). The publishable key below is public by design:
   Row Level Security in supabase/migrations/ protects the data. Never put the service_role key here. */
const SUPABASE_URL = 'https://xrjkwjcftuthdgdebxwg.supabase.co';
const SUPABASE_KEY = 'sb_publishable_chg_qwfzBHba_GZZZRFGyw__jI7v4oe';
const PAGE_LIMIT = 5;

const sb = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
const $ = (s, root = document) => root.querySelector(s);

const photoUrl = path => path ? `${SUPABASE_URL}/storage/v1/object/public/photos/${path}` : '';

// Vercel serves /p/<slug>; anywhere else (GitHub Pages, a local server) falls back to ?p=<slug>
function pageLink(slug) {
    if (location.hostname.endsWith('.vercel.app') || location.pathname.startsWith('/p/')) return `${location.origin}/p/${slug}`;
    return new URL(`ask-her-out.html?p=${slug}`, location.href).href;
}

function toast(text) {
    let t = $('.toast');
    if (!t) { t = document.createElement('div'); t.className = 'toast'; t.setAttribute('role', 'status'); document.body.appendChild(t); }
    t.textContent = text;
    t.classList.add('show');
    clearTimeout(t._h);
    t._h = setTimeout(() => t.classList.remove('show'), 2200);
}

async function copyText(text) {
    try { await navigator.clipboard.writeText(text); toast('Link copied 💕'); }
    catch { prompt('Copy your link:', text); }
}

// Friendly messages for the errors the database raises on purpose
function friendlyError(err) {
    const m = (err && (err.message || err.error_description)) || String(err);
    if (/page_limit/.test(m)) return `You can have up to ${PAGE_LIMIT} pages. Delete one to make another.`;
    if (/duplicate key|pages_slug_key/.test(m)) return 'That link is taken. Try another one.';
    if (/rate limit|rate_limit|too many/i.test(m)) return 'Too many tries. Wait a few minutes and try again.';
    if (/slug_check|check constraint "pages_slug/.test(m)) return 'Links use 3–40 lowercase letters, numbers and dashes.';
    if (/exceeded the maximum allowed size|Payload too large/i.test(m)) return 'That photo is too big (2 MB max).';
    return m;
}

// Signed-in user in the nav: the avatar opens a small menu with sign out
function renderUser(user) {
    const right = $('.nav-right');
    const letter = (user.email || '?')[0].toUpperCase();
    right.insertAdjacentHTML('beforeend', `<button class="avatar" type="button" aria-haspopup="true" aria-expanded="false" aria-label="Account">${letter}</button>
        <div class="glass menu hidden" role="menu"><small></small><button type="button" role="menuitem" data-signout>Sign out</button></div>`);
    const btn = right.querySelector('.avatar'), menu = right.querySelector('.menu');
    menu.querySelector('small').textContent = user.email;
    btn.addEventListener('click', () => {
        const open = menu.classList.toggle('hidden') === false;
        btn.setAttribute('aria-expanded', String(open));
    });
    document.addEventListener('click', e => { if (!right.contains(e.target)) menu.classList.add('hidden'); });
    menu.querySelector('[data-signout]').addEventListener('click', async () => { await sb.auth.signOut(); location.reload(); });
}

// Magic-link sign-in card (no password). Supabase sends the email; the link brings them back to this page.
function renderSignIn(container, { title, text }) {
    container.innerHTML = `
        <div class="glass signin-card">
            <img class="sticker" src="Pics/cat-heart.jpg" alt="A kitten holding out a pink heart" width="172" height="148">
            <h2></h2><p></p>
            <form>
                <label class="sr-only" for="signinEmail">Your email</label>
                <input class="field" type="email" id="signinEmail" placeholder="you@email.com" autocomplete="email" required>
                <button class="btn btn-sun" type="submit">Send me a magic link →</button>
                <p class="status" aria-live="polite"></p>
            </form>
        </div>`;
    container.querySelector('h2').textContent = title;
    container.querySelector('p').textContent = text;
    const form = container.querySelector('form'), status = container.querySelector('.status');
    form.addEventListener('submit', async e => {
        e.preventDefault();
        const email = form.querySelector('input').value.trim();
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return void (status.textContent = 'That email doesn\'t look right.');
        const btn = form.querySelector('button');
        btn.disabled = true;
        status.className = 'status';
        status.textContent = 'Sending…';
        const { error } = await sb.auth.signInWithOtp({ email, options: { emailRedirectTo: location.href.split('#')[0] } });
        btn.disabled = false;
        if (error) { status.className = 'status err'; status.textContent = friendlyError(error); return; }
        status.className = 'status ok';
        status.textContent = '✓ Check your inbox and tap the link. You can close this tab.';
    });
}

async function currentUser() {
    const { data } = await sb.auth.getSession();
    return data.session ? data.session.user : null;
}
