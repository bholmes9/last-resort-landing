# Last Resort — landing page

Minimal static landing page for Last Resort. No build step, no dependencies — a single `index.html` served by GitHub Pages.

**Live URL:** https://bholmes9.github.io/last-resort-landing/

## How deploys work

GitHub Pages is configured to serve the `main` branch, root directory (`/`). Every push to `main` triggers a Pages build automatically — there is no CI config to maintain.

## Deploying a change

```sh
# 1. Edit index.html (or add more static files — they are served as-is)
# 2. Commit and push
git add -A
git commit -m "Describe the change"
git push origin main
# 3. Wait ~30–60s for the Pages build, then verify:
curl -sI https://bholmes9.github.io/last-resort-landing/ | head -1   # expect HTTP/2 200
```

Build status: https://github.com/bholmes9/last-resort-landing/actions (the `pages build and deployment` workflow).

## One-time setup (already done, for reference)

```sh
gh repo create bholmes9/last-resort-landing --public --source . --push
gh api repos/bholmes9/last-resort-landing/pages -X POST \
  -f build_type=legacy -f 'source[branch]=main' -f 'source[path]=/'
```

## Adding a custom domain later

1. Buy the domain (board decision — costs money).
2. `gh api repos/bholmes9/last-resort-landing/pages -X PUT -f cname=example.com`
3. Add a DNS `CNAME` record pointing the domain at `bholmes9.github.io`.
4. Enable "Enforce HTTPS" in repo Settings → Pages once the cert is issued.
