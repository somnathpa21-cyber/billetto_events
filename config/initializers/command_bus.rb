require Rails.root.join("lib/command")

Rails.application.config.after_initialize do
  command_bus = Command::Bus.new

  command_bus.register_handler(Voting::Handlers::LikeEventHandler.new)
  command_bus.register_handler(Voting::Handlers::DislikeEventHandler.new)

  Rails.configuration.command_bus = command_bus
end