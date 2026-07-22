# Discourse Homepage Redirect

**Server-side homepage redirect for logged-in members. Guests keep the default homepage untouched.**

This plugin is the *audience-split* half of the VC landing architecture:

- The **homepage claim** (`custom_homepage`) stays with the theme (VC-Canvas / Community Plaza). Guests hitting `/` get the Plaza + landing banner, exactly as before. Nothing in this plugin touches the claim.
- **Logged-in members** hitting a home path are 302-redirected server-side to a chosen internal destination — on VC, the Feed (`/feed`), the members' front door.

Because the redirect fires only for authenticated users, SEO, crawlers, and first-time visitors are unaffected by design.

## How it works

A `before_action` on `ApplicationController` (included via a concern, `reloadable_patch`-safe) checks, in cost order:

1. Plugin enabled, user logged in
2. Request path is one of the configured **home paths** (default: `/` only)
3. A valid, internal, non-looping **destination** is configured
4. The request is a full-page **HTML GET** — never XHR, JSON, API, or user-API traffic
5. No `?noredirect=1` bypass present
6. The user is in the **allowed groups** (empty = all members)
7. The **mode** permits it (`always`, or `once_per_session` not yet consumed)

Then it issues a **302** (never 301 — the decision is per-user and per-setting; a cached permanent redirect would outlive both).

## Settings

| Setting | Default | Purpose |
|---|---|---|
| `homepage_redirect_enabled` | `true` | Master switch. Off = stock Discourse behavior for everyone. |
| `homepage_redirect_destination_path` | `/feed` | Internal path members land on. Must start with a single `/`. Invalid/external values disable the redirect rather than half-working. |
| `homepage_redirect_paths` | `/` | Paths treated as "home". Deliberately **not** `/latest`: with mode `always`, redirecting `/latest` would make the Latest list permanently unreachable for members. |
| `homepage_redirect_allowed_groups` | *(empty)* | Scope the redirect to specific groups. Empty = all logged-in members. |
| `homepage_redirect_mode` | `always` | `always` = home paths **are** the destination for members. `once_per_session` = one nudge, then home paths behave normally (the pre-1.0 behavior, now explicit). |

## Safety properties

- **Loop guard** — a destination that is itself a home path is refused outright.
- **Internal-only** — destinations must start with a single `/`; protocol-relative (`//host`) and absolute URLs are rejected.
- **SPA-safe** — JSON/XHR/API requests are never redirected, so background fetches and app traffic are untouched.
- **Bypass** — append `?noredirect=1` to any URL to skip the redirect (support/debugging).

## Installation

```yml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/BrianCraword/discourse-homepage-redirect.git
```

Then `cd /var/discourse && ./launcher rebuild app`. Setting changes take effect immediately, no rebuild.

## Requirements

Discourse **3.1.0** or newer.

## License

MIT.
