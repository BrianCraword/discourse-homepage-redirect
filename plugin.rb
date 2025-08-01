# name: discourse-homepage-redirect
# about: Sets AI Conversations as the default homepage for logged-in users
# version: 0.2.0
# authors: YourName
# url: https://your-discourse-site.example.com
# required_version: 3.1.0

after_initialize do
  ApplicationController.class_eval do
    before_action :redirect_logged_in_users_to_ai_home

    def redirect_logged_in_users_to_ai_home
      logged_in_homepage = "/discourse-ai/ai-bot/conversations"
      homepage_paths = ["/", "/latest"]

      if current_user && homepage_paths.include?(request.path)
        redirect_to(logged_in_homepage) and return
      end
    end
  end
end
