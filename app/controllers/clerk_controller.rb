class ClerkController < ApplicationController
  def sign_in
  end

  def sign_up
  end

  def status
    if clerk.user?
      render plain: "Authenticated. Clerk user ID: #{clerk.user_id}"
    else
      render plain: "Not authenticated", status: :unauthorized
    end
  end
end