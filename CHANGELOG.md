# Changelog — discourse-homepage-redirect

Code is truth: the `# version:` header in `plugin.rb`, `about.json`, and the
top entry here move in lockstep. Every build gets a number.

---
[1.0.0] - 2026-07-21

**"The Audience Split"** — the maturity release. The plugin's role is now
precisely defined within the VC landing architecture: the homepage *claim*
(`custom_homepage`) stays with VC-Canvas (Plaza + guest landing banner
untouched); this plugin performs the *audience split* — logged-in members
hitting home are sent to the Feed. Decided against moving the claim into a
plugin: the theme's mechanism is proven, and keeping it preserves the Plaza
as a live, re-wireable surface.

Breaking/behavioral changes from 0.x:

  * **Default destination is now `/feed`** (was `/discourse-ai/ai-bot/
    conversations`). Sites that never overrode the old default will flip to
    `/feed` on deploy — verify `homepage_redirect_destination_path` in Admin
    → Settings after deploying if you want the old target.
  * **Default mode is `always`** — home paths ARE the destination for
    members. The old hard-coded once-per-session guard is now the explicit
    `once_per_session` mode choice.
  * **`/latest` is no longer a home path by default** (was hard-coded).
    With `always` mode, redirecting `/latest` would make the Latest nav
    destination permanently unreachable for members. Add it back via
    `homepage_redirect_paths` only if truly intended.

New:

  * `homepage_redirect_paths` (list) — configurable home paths.
  * `homepage_redirect_allowed_groups` (group_list) — scope to groups.
  * `homepage_redirect_mode` (enum) — `always` | `once_per_session`.
  * `?noredirect=1` bypass on any URL (support/debugging).
  * Loop guard: a destination that is itself a home path is refused.
  * Destination validation: internal single-`/` paths only; protocol-
    relative and absolute URLs rejected; trailing slashes normalized.
  * Request guards: HTML GET only — never XHR, JSON, API, or user-API.
  * 302 always (never 301 — per-user decisions must not be cached).
  * Concern-based include with `reloadable_patch` + double-include guard
    (replaces the raw `class_eval` monkeypatch).
  * Request specs covering every guard branch.
  * Server locale strings for all settings.
  * `about.json` reconciled with `plugin.rb` (0.x had 0.1.0 vs 0.4.0
    drift); README rewritten to document only what the code does (0.x's
    README described four settings that never existed — they now do, in
    their 1.0.0 form).

---
[0.4.0 and earlier] - 2025

Pre-changelog era. A single hard-coded behavior: logged-in users hitting
`/` or `/latest` were 302'd once per session to the destination setting
(default: AI conversations). `about.json` lagged at 0.1.0. No specs, no
locale strings, no validation, no bypass.
