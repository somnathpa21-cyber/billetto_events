class ApplicationController < ActionController::Base
  include Clerk::Authenticatable

  helper_method :clerk_signed_in?, :clerk_user_id

  private

  def clerk_signed_in?
    clerk.user?
  end

  def clerk_user_id
    clerk.user_id
  end

  def require_clerk_session!
    redirect_to clerk.sign_in_url unless clerk.session
  end
end