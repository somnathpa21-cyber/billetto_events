class ClerkTestMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if env["HTTP_X_TEST_CLERK_USER_ID"].present?
      env["clerk"] = Clerk::Proxy.new(
        session_claims: {
          "sub" => env["HTTP_X_TEST_CLERK_USER_ID"]
        }
      )
    end

    @app.call(env)
  end
end