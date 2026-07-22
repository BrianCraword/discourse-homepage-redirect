# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Homepage redirect", type: :request do
  fab!(:user)
  fab!(:group) { Fabricate(:group).tap { |g| g.add(user) } }
  fab!(:other_group) { Fabricate(:group) }

  before do
    SiteSetting.homepage_redirect_enabled = true
    SiteSetting.homepage_redirect_destination_path = "/feed"
    SiteSetting.homepage_redirect_paths = "/"
    SiteSetting.homepage_redirect_allowed_groups = ""
    SiteSetting.homepage_redirect_mode = "always"
  end

  describe "anonymous visitors" do
    it "are never redirected — the guest landing survives" do
      get "/"
      expect(response.status).to eq(200)
    end
  end

  describe "logged-in members" do
    before { sign_in(user) }

    it "are redirected from / to the destination with a 302" do
      get "/"
      expect(response).to redirect_to("/feed")
      expect(response.status).to eq(302)
    end

    it "are redirected on every visit in always mode" do
      get "/"
      expect(response).to redirect_to("/feed")
      get "/"
      expect(response).to redirect_to("/feed")
    end

    it "are redirected only once in once_per_session mode" do
      SiteSetting.homepage_redirect_mode = "once_per_session"
      get "/"
      expect(response).to redirect_to("/feed")
      get "/"
      expect(response.status).to eq(200)
    end

    it "are not redirected when the plugin is disabled" do
      SiteSetting.homepage_redirect_enabled = false
      get "/"
      expect(response.status).to eq(200)
    end

    it "are not redirected on JSON requests" do
      get "/.json"
      expect(response.status).not_to eq(302)
    end

    it "are not redirected on XHR requests" do
      get "/", headers: { "X-Requested-With" => "XMLHttpRequest" }
      expect(response.status).not_to eq(302)
    end

    it "respects the ?noredirect=1 bypass" do
      get "/?noredirect=1"
      expect(response.status).to eq(200)
    end

    it "are not redirected from non-home paths" do
      get "/about"
      expect(response.status).not_to eq(302)
    end
  end

  describe "loop and destination safety" do
    before { sign_in(user) }

    it "does nothing when the destination is blank" do
      SiteSetting.homepage_redirect_destination_path = ""
      get "/"
      expect(response.status).to eq(200)
    end

    it "does nothing when the destination is a home path (loop guard)" do
      SiteSetting.homepage_redirect_paths = "/|/feed"
      get "/"
      expect(response.status).to eq(200)
    end

    it "rejects protocol-relative destinations" do
      SiteSetting.homepage_redirect_destination_path = "//evil.example.com"
      get "/"
      expect(response.status).to eq(200)
    end

    it "rejects external destinations" do
      SiteSetting.homepage_redirect_destination_path = "https://evil.example.com"
      get "/"
      expect(response.status).to eq(200)
    end

    it "normalizes trailing slashes on the destination" do
      SiteSetting.homepage_redirect_destination_path = "/feed/"
      get "/"
      expect(response).to redirect_to("/feed")
    end
  end

  describe "group scoping" do
    before { sign_in(user) }

    it "redirects members of an allowed group" do
      SiteSetting.homepage_redirect_allowed_groups = group.id.to_s
      get "/"
      expect(response).to redirect_to("/feed")
    end

    it "does not redirect members outside the allowed groups" do
      SiteSetting.homepage_redirect_allowed_groups = other_group.id.to_s
      get "/"
      expect(response.status).to eq(200)
    end
  end
end
