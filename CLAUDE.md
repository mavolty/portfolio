# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

No build, no bundler, no test suite. Just static files.

**Preview locally** (any static server works — pick one):
```bash
python3 -m http.server 8000     # → http://localhost:8000/portfolio.html
# or
npx serve .
```

**Deploy to production**:
```bash
bash deploy.sh
```
Rsyncs everything except `.git`, `deploy.sh`, and `nginx.conf` to `personal:/var/www/portfolio` (requires `ssh personal` alias in `~/.ssh/config` pointing at the VPS). `--delete` is on, so removing a file locally removes it from the server.

**Update nginx config on the VPS** (config lives only locally, never rsynced):
```bash
ssh personal "sudo tee /etc/nginx/sites-available/shusain.xyz > /dev/null" < nginx.conf
ssh personal "sudo nginx -t && sudo systemctl reload nginx"
```

## Architecture

Single-page static site — no build step, no framework, no bundler. The three load-bearing files are:

- **`portfolio.html`** — all markup and all JavaScript (single inline `<script>` starts at line 525)
- **`styles.css`** — all styles including the animation system and OKLCH theme tokens
- **`favicon.svg`** — inline SVG favicon (dark rect + "sh" monogram)

Also checked in: `robots.txt`, `sitemap.xml` (SEO), `deploy.sh`, `nginx.conf` (infra — excluded from rsync).

### Animation system

Gated on `.js` class added to `<html>` at script load (prevents FOIC without JS). Elements with `data-animate` start hidden; an `IntersectionObserver` adds `.in` when they enter the viewport, triggering CSS transitions. Stagger delay uses `--i` CSS custom property: `transition-delay: calc(var(--i, 0) * 60ms)`.

Variants:
- `data-animate` — slide up 14px + fade
- `data-animate="hero"` — slide up 32px + fade, slower (1000ms)
- `data-animate="fade"` — fade only, no translate

All transitions are wrapped in `@media (prefers-reduced-motion: no-preference)`.

### Theme

Two independent axes, both persisted in `localStorage` and applied by `applyTweaks()`:

- **`theme`** — `'light' | 'dark'`, toggled via the `◐` button. Swapped by setting `data-theme="dark"` on `<html>`. Also updates `<meta name="theme-color">` via `THEME_COLOR` map.
- **`accent`** — `'red' | 'ink' | 'olive'` (see `ACCENT_MAP`). Sets the `--accent` CSS custom property inline on `<html>`. No UI toggle yet — change via DevTools / localStorage.

All other colors use OKLCH tokens (`--paper`, `--ink`, `--ink-2`, etc.) defined in `styles.css`.

### JS features (all inline in portfolio.html)

- **Jakarta clock** — ticks every 1s in the footer `#liveClock`. Uses `Intl.DateTimeFormat` with `timeZone: 'Asia/Jakarta'` so it's correct regardless of the visitor's local timezone.
- **`g + key` nav shortcuts** — 800ms window after pressing `g`. Map: `n`→`#now`, `w`→`#work`, `e`→`#experience`, `t`→`#tooling`, `c`→`#contact`. Ignored while typing in inputs.
- **IntersectionObserver scroll-reveal** — only attaches if `prefers-reduced-motion: no-preference`; otherwise elements skip straight to the `.in` state.

When adding a new section, give it an `id` for the `g+key` map and `data-animate` attributes on child elements.

## Infrastructure

- **VPS**: Hostinger `srv527879` — SSH alias `personal`
- **Domain**: `shusain.xyz` proxied through Cloudflare (orange cloud ON)
- **Web server**: nginx bound to `156.67.219.59:80` and `156.67.219.59:443` (specific IP, not wildcard — Tailscale holds the wildcard on port 443)
- **SSL on origin**: self-signed cert at `/etc/ssl/certs/shusain.crt` — fine because Cloudflare terminates TLS for visitors
- **Cloudflare SSL mode**: Full (not Strict) — accepts self-signed origin cert
- **nginx root**: `/var/www/portfolio`, index `portfolio.html`
