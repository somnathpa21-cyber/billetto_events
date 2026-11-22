require Rails.root.join("lib/command")

Rails.application.config.after_initialize do
  Rails.configuration.command_bus = Command::Bus.new
end