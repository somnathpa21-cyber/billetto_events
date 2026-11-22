module Command
  class Bus
    class UnhandledCommandError < StandardError; end

    def initialize(handlers: [])
      @handlers = handlers
    end

    def register_handler(handler)
      @handlers << handler
    end

    def call(command)
      validate!(command)

      ActiveRecord::Base.transaction do
        ActiveSupport::Notifications.instrument(
          "command.call",
          command: command.class.name
        ) do
          dispatch(command)
        end
      end
    end

    private

    attr_reader :handlers

    def validate!(command)
      return unless command.respond_to?(:valid?)

      raise ActiveModel::ValidationError, command unless command.valid?
    end

    def dispatch(command)
      if command.is_a?(Command::Executable)
        return command.call
      end

      handler = handlers.find do |registered_handler|
        registered_handler.class.handled_commands.key?(command.class)
      end

      raise UnhandledCommandError, "No handler registered for #{command.class}" unless handler

      method_name = handler.class.handled_commands.fetch(command.class)
      handler.send(method_name, command)
    end
  end
end