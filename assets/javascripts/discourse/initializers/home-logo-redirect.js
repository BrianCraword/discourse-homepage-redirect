import { apiInitializer } from "discourse/lib/api";
import DiscourseURL from "discourse/lib/url";
import { getURL } from "discourse-common/lib/get-url";

export default apiInitializer("0.12.1", (api) => {
  api.onPageChange(() => {
    // Only affect authenticated users (keep anon/SEO unchanged)
    if (!api.getCurrentUser()) return;

    const dest = (settings.homepage_redirect_destination_path || "").trim();
    if (!dest) return;

    // Find the header logo anchor (covers desktop & mobile)
    const anchor =
      document.querySelector("#site-logo") ||
      document.querySelector("a.home-logo") ||
      document.querySelector(".d-header .title a");

    if (!anchor) return;

    // Make the actual link point to your configured destination
    const url = getURL(dest);
    anchor.setAttribute("href", url);

    // Avoid double-binding on subsequent page changes
    if (anchor.dataset.wiredHomeLogoRedirect === "1") return;
    anchor.dataset.wiredHomeLogoRedirect = "1";

    // Intercept primary-click to route via SPA (preserves base path)
    anchor.addEventListener("click", (e) => {
      if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey || e.button !== 0) return;
      e.preventDefault();
      DiscourseURL.routeTo(url);
    });
  });
});
