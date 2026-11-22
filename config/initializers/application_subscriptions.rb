require Rails.root.join("lib/application_subscriptions")

Rails.application.config.after_initialize do
  ApplicationSubscriptions.new(
    event_store: Rails.configuration.event_store
  ).register
end