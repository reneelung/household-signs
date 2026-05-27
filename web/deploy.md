# Deploying the AASA + landing page to Cloudflare Pages

Free, ~10 minutes, no credit card required.

## 1 · Edit the AASA placeholders first

Open `apple-app-site-association` and fill in:
- **TEAM_ID** — 10-character Apple Developer team ID (Xcode → Signing & Capabilities → Team, or developer.apple.com → Membership)
- **com.yourorg.quickflip** — your real bundle ID

Optionally also edit `index.html` to swap `YOUR_APP_STORE_ID` once you have one. Until then, the Get QuickFlip button just won't go anywhere useful — fine for now.

## 2 · Sign up for Cloudflare

https://dash.cloudflare.com/sign-up — free account, no card.

## 3 · Create a Pages project

1. In the dashboard sidebar: **Workers & Pages** → **Pages** tab
2. **Create application** → **Pages** → **Upload assets**
3. Project name: `quickflip-app` (this becomes `quickflip-app.pages.dev`)
4. Click **Create project**

## 4 · Upload the `web/` folder

1. Drag the entire `web/` folder onto the upload area (the one from this zip)
2. Click **Deploy site**
3. Wait ~20 seconds for the first deploy

## 5 · Verify the AASA is reachable

In your terminal:

```bash
curl -I https://quickflip-app.pages.dev/.well-known/apple-app-site-association
```

You want to see:
```
HTTP/2 200
content-type: application/json
```

If you get a 404, check that the file inside `web/.well-known/` was uploaded (it's hidden — make sure your file manager includes dotfiles). If you get `content-type: text/plain`, Cloudflare's auto-detection sometimes misses it; you can force JSON by adding a `_headers` file:

```
/.well-known/apple-app-site-association
  Content-Type: application/json
```

(See the optional `_headers` file in `web/` — uncomment and re-upload if needed.)

## 6 · Future updates

To update the landing page or AASA later:
- Edit the file locally
- Drag `web/` into the same Pages project (it overwrites)
- Or connect a Git repo for auto-deploy on push (Pages → Settings → Builds & deployments)

## 7 · Custom domain later

Once you buy a real domain (e.g. `quickflip.app`):
- Cloudflare Pages → your project → **Custom domains** → **Set up a custom domain**
- Follow the DNS steps (about 10 minutes)
- Add the new hostname to your `applinks:` entitlement alongside the `.pages.dev` one during the cutover, so old TestFlight links keep working
