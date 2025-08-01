# name: discourse-login-redirect
# about: Redirect logged-in users to the AI conversations page
# version: 0.1.0
# authors: YourName
# url: https://your-discourse-site.example.com
# required_version: 3.1.0

after_initialize do
  # Re-open the main ApplicationController to add a before_action filter
  ApplicationController.class_eval do
    # Before any controller action runs, check for logged-in homepage access
    before_action :redirect_logged_in_homepage

    def redirect_logged_in_homepage
      # Define the target path for logged-in users:
      logged_in_homepage_path = "/discourse-ai/ai-bot/conversations"
      # If a user is logged in and trying to access the root path ("/"), redirect them.
      if current_user && request.path == "/" && request.path != logged_in_homepage_path
        redirect_to logged_in_homepage_path
        # Mark this response as fully handled to stop any further processing
        self.finished = true if respond_to?(:finished=)
      end
    end
  end
end
