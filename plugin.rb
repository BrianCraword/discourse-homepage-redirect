# name: discourse-homepage-redirect
# about: Sets AI Conversations as the default homepage for logged-in users
# version: 0.2.0
# authors: YourName
# url: https://your-discourse-site.example.com
# required_version: 3.1.0

after_initialize do

  require_dependency 'discourse_constraint'

  # This constraint checks if the user is logged in
  class LoggedInConstraint
    def matches?(request)
      current_user = CurrentUser.lookup_from_env(request.env)
      current_user.present?
    end
  end

  # Redirect "/" and "/latest" to the AI Conversations page for logged-in users
  Discourse::Application.routes.prepend do
    constraints(LoggedInConstraint.new) do
      get '/' => redirect('/discourse-ai/ai-bot/conversations')
      get '/latest' => redirect('/discourse-ai/ai-bot/conversations')
    end
  end

end

