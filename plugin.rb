# frozen_string_literal: true

# name: discourse-homepage-redirect
# about: Server-side homepage redirect for logged-in members. Members hitting the site's home path(s) are sent to a chosen internal destination (e.g. the VC Feed); guests keep the default homepage untouched. The audience-split half of the VC landing architecture — the custom_homepage claim stays with the theme.
# version: 1.0.0
# authors: Brian Crawford
# url: https://github.com/BrianCraword/discourse-homepage-redirect
# required_version: 3.1.0

enabled_site_setting :homepage_redirect_enabled

module ::HomepageRedirect
  PLUGIN_NAME = "discourse-homepage-redirect"

  # Normalize an internal path for comparison and validation.
  # Returns nil for anything unsafe or non-internal:
  #   - blank / whitespace-only
  #   - not starting with "/"
  #   - protocol-relative ("//evil.example") — a redirect_to with that
  #     would leave the site; never allow it
  # Trailing slash is stripped (except for root) so "/feed/" == "/feed".
  # Query strings are the caller's concern; settings should hold bare paths.
  def self.normalize_path(path)
    return nil if path.blank?

    p = path.to_s.strip
    return nil unless p.start_with?("/")
    return nil if p.start_with?("//")

    p = p.chomp("/") while p.length > 1 && p.end_with?("/")
    p
  end

  # The validated redirect destination, or nil when unset/invalid.
  def self.destination
    normalize_path(SiteSetting.homepage_redirect_destination_path)
  end

  # The set of paths treated as "home" (normalized, invalid entries dropped).
  def self.homepage_paths
    SiteSetting
      .homepage_redirect_paths
      .to_s
      .split("|")
      .filter_map { |p| normalize_path(p) }
      .uniq
  end

  # A destination that is itself a home path would redirect to a path that
  # redirects again — refuse it outright. This is the loop guard.
  def self.safe_destination
    dest = destination
    return nil if dest.blank?
    return nil if homepage_paths.include?(dest)
    dest
  end

  module ControllerExtension
    extend ActiveSupport::Concern

    included { before_action :homepage_redirect_if_member }

    # NB: deliberately NOT named `status`/`session`/`redirect`/etc — reserved
    # Rails action names are excluded from action_methods and dispatch-404
    # silently (Pitfall Library). The prefixed name is dispatch-safe.
    def homepage_redirect_if_member
      return unless SiteSetting.homepage_redirect_enabled

      # Guests keep the default homepage (Plaza + landing banner) untouched.
      # This single check IS the audience split of the VC landing design.
      return if current_user.blank?

      # Cheapest checks first: is this request even aimed at a home path?
      path = ::HomepageRedirect.normalize_path(request.path)
      return if path.blank?
      return unless ::HomepageRedirect.homepage_paths.include?(path)

      destination = ::HomepageRedirect.safe_destination
      return if destination.blank?
      return if destination == path

      # Only full-page HTML GET navigations are ever redirected.
      # Never JSON/XHR (the SPA's background fetches to "/" -era endpoints),
      # never API/user-API traffic, never POSTs mid-flow.
      return unless request.get?
      return if request.xhr?
      return if respond_to?(:is_api?, true) && is_api?
      return if respond_to?(:is_user_api?, true) && is_user_api?
      return unless request.format&.html?

      # Support/debug escape hatch: ?noredirect=1 always wins.
      return if params[:noredirect].present?

      # Optional group scoping. Empty = every logged-in member.
      group_ids = SiteSetting.homepage_redirect_allowed_groups_map
      return if group_ids.present? && !current_user.in_any_groups?(group_ids)

      # "always" (default): the destination IS home for members — every hit
      # on a home path lands there. "once_per_session": a single nudge, then
      # home paths behave normally (the pre-1.0 behavior, now explicit).
      if SiteSetting.homepage_redirect_mode == "once_per_session"
        return if session[:homepage_redirected]
        session[:homepage_redirected] = true
      end

      # 302, never 301 — the decision is per-user and per-setting; a cached
      # permanent redirect would outlive both.
      redirect_to destination, status: 302
    end
  end
end

after_initialize do
  reloadable_patch do
    unless ApplicationController.include?(::HomepageRedirect::ControllerExtension)
      ApplicationController.include(::HomepageRedirect::ControllerExtension)
    end
  end
end
