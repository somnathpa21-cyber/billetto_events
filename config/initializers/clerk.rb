Clerk.configure do |config|
  config.secret_key =
    Rails.application.credentials.dig(:clerk, :secret_key)

  config.publishable_key =
    Rails.application.credentials.dig(:clerk, :publishable_key)
end

ENV["CLERK_SIGN_IN_URL"] ||= "/sign-in"
ENV["CLERK_SIGN_UP_URL"] ||= "/sign-up"
ENV["CLERK_SIGN_OUT_URL"] ||= "/"