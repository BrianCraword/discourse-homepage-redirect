# name: discourse-homepage-redirect
# about: Redirect unauthenticated users from AI conversations to categories
# version: 0.5.0
# authors: Brian Crawford
# url: https://victoriouschristians.com
# required_version: 3.1.0

enabled_site_setting :homepage_redirect_enabled

after_initialize do
  ApplicationController.class_eval do
    # Rescue permission errors and redirect anonymous users
    rescue_from Discourse::InvalidAccess do |e|
      if !current_user && request.path.start_with?("/discourse-ai/ai-bot")
        redirect_to "/categories"
      else
        raise e  # Re-raise for normal error handling
      end
    end
  end
end
