module Command
  module Executable
    def self.included(base)
      base.include ActiveModel::Model
      base.include ActiveModel::Attributes
    end
  end
end