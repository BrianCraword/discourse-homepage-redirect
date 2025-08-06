# Discourse Homepage Redirect Plugin

Make a **different homepage for logged-in members** without disturbing guests.

* **What it does**  
  When a user is authenticated and visits any of the forum “home” paths (`/` or `/latest`), the plugin transparently redirects them to an admin-chosen URL (for example your AI chat page at `/discourse-ai/ai-bot/conversations`).  
  Anonymous visitors still see the normal Discourse homepage.

* **Why you might need it**  
  - Send members straight to a chat experience, a knowledge-base topic list, or a custom dashboard.  
  - Keep SEO and landing-page behavior unchanged for logged-out readers.  
  - Avoid fragile client-side hacks or theme-component work-arounds; this runs server-side.

---

## Requirements

* Discourse **3.1.0** or newer (tests-passed, beta, or stable).  
* Works on the official Docker install or any supported production image.

---

## Installation

1. **Add the plugin** to your container definition (`containers/app.yml`):

   ```yml
   hooks:
     after_code:
       - exec:
           cd: $home/plugins
           cmd:
             - git clone https://github.com/BrianCraword/discourse-homepage-redirect.git
Rebuild the container:

bash
Copy
Edit
cd /var/discourse
./launcher rebuild app
After the site boots, visit Admin → Settings → Plugins and search for “homepage redirect”.

Configuration
Setting	Purpose	Default
homepage_redirect_enabled	Master on/off toggle	true
homepage_redirect_destination_path	URL to send logged-in users to  ⇢ must be an internal path such as /my, /categories, /discourse-ai/ai-bot/conversations	/discourse-ai/ai-bot/conversations

Changes take effect immediately—no additional rebuild required.

Optional extras (you can uncomment them in config/settings.yml)
Setting	Example value	Effect
homepage_redirect_groups	staff, ai_premium	Only members of these groups are redirected
homepage_redirect_extra_paths	/categories,/top	Treat these routes as “home” too
homepage_redirect_first_login_only	true	Redirect once after account is created, not forever
homepage_redirect_allow_param	true	Add ?noredirect=1 to a URL to bypass redirection (useful for support)

How it works
During each request the plugin inserts a before_action in ApplicationController:

ruby
Copy
Edit
if current_user && ["/", "/latest"].include?(request.path)
  redirect_to SiteSetting.homepage_redirect_destination_path
end
Anonymous traffic is ignored, ensuring bots and new visitors keep the default experience.

Upgrading
git pull in the plugin folder (or let your container clone a newer commit) and rebuild the app as usual.

Removing the plugin
Comment out or delete the git clone line in app.yml.

./launcher rebuild app – Discourse will boot without the plugin.


MIT – free to use, modify, and distribute.

Happy redirecting!
