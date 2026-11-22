
require "rails_helper"
require Rails.root.join("lib/command")

class TestExecutableCommand
  include Command::Executable

  attribute :event_id, :string

  validates :event_id, presence: true

  def call
    "executed"
  end
end

class TestHandlerCommand
  include ActiveModel::Model

  attr_accessor :event_id
end

class TestCommandHandler
  include Command::Handler

  handles TestHandlerCommand, :execute

  def execute(command)
    "handled #{command.event_id}"
  end
end

RSpec.describe Command::Bus do
  let(:bus) { described_class.new }

  describe "#call" do
    context "with an executable command" do
      it "executes the command" do
        command = TestExecutableCommand.new(event_id: "event-123")

        expect(bus.call(command)).to eq("executed")
      end

      it "rejects an invalid command" do
        command = TestExecutableCommand.new(event_id: nil)

        expect { bus.call(command) }
          .to raise_error(ActiveModel::ValidationError)
      end
    end

    context "with a handler-based command" do
      it "dispatches the command to its registered handler" do
        bus.register_handler(TestCommandHandler.new)

        command = TestHandlerCommand.new(event_id: "event-123")

        expect(bus.call(command)).to eq("handled event-123")
      end
    end

    it "raises an error when no handler is registered" do
      command = Class.new.new

      expect { bus.call(command) }
        .to raise_error(Command::Bus::UnhandledCommandError)
    end
  end
end
