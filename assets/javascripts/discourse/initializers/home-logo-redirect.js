import { apiInitializer } from "discourse/lib/api";
import DiscourseURL from "discourse/lib/url";
import { getURL } from "discourse-common/lib/get-url";

export default apiInitializer("0.12.1", (api) => {
  api.onPageChange(() => {
    try {
      // Only change behavior for authenticated users
      if (!api.getCurrentUser()) return;

      // In plugins, read settings from the container (not "settings")
      const siteSettings = api.container.lookup("site-settings:main");
      const dest = (siteSettings.homepage_redirect_destination_path || "").trim();
      if (!dest) return;

      // Find the header logo link (desktop & mobile)
      const anchor =
        document.querySelector("a.home-logo") ||
        document.querySelector("#site-logo") ||
        document.querySelector(".d-header .title a");
      if (!anchor) return;

      const url = getURL(dest);

      // Keep href correct even if header is re-rendered
      anchor.setAttribute("href", url);

      // Idempotent listener
      if (anchor.dataset.homeLogoRedirectBound === "1") return;
      anchor.dataset.homeLogoRedirectBound = "1";

      anchor.addEventListener("click", (e) => {
        // Respect modifier/middle clicks etc.
        if (e.defaultPrevented) return;
        if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey || e.button !== 0) return;
        e.preventDefault();
        DiscourseURL.routeTo(url);
      });
    } catch (err) {
      // Don't surface admin banner; log to console only
      // eslint-disable-next-line no-console
      console.error("[discourse-homepage-redirect] onPageChange error:", err);
    }
  });
});
