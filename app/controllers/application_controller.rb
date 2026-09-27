# typed: true
# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ActionPolicy::Controller

  layout false

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_current_user

  authorize :user, through: :current_user

  private

  # Replace with your authentication lookup, e.g. User.find_by(id: session[:user_id]).
  sig { void }
  def set_current_user
    Current.user = nil
  end

  sig { returns(T.untyped) }
  def current_user
    Current.user
  end
end
