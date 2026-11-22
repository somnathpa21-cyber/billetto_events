module Command
  module Handler
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def handles(command_class, method_name)
        handled_commands[command_class] = method_name
      end

      def handled_commands
        @handled_commands ||= {}
      end
    end
  end
end