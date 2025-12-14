# name: discourse-homepage-redirect
# about: Configurable homepage redirect for logged-in users
# version: 0.4.0
# authors: Brian Crawford
# url: https://victoriouschristians.com
# required_version: 3.1.0

# Tells Discourse to load this plugin only when the toggle is ON
enabled_site_setting :homepage_redirect_enabled

after_initialize do
  ApplicationController.class_eval do
    before_action :redirect_logged_in_homepage

    def redirect_logged_in_homepage
      # Skip unless admin toggle is enabled
      return unless SiteSetting.homepage_redirect_enabled

      destination = SiteSetting.homepage_redirect_destination_path.presence
      return if destination.blank?                         # nothing set
      return if request.path == destination                # already there

      # Define which "home" routes we want to override
      homepage_paths = ["/", "/latest"]

      if current_user && homepage_paths.include?(request.path)
        # Only redirect if we haven't already done so this session
        unless session[:homepage_redirected]
          session[:homepage_redirected] = true
          redirect_to destination
        end
      end
    end
  end
end
