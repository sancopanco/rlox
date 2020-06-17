module Lox
  # Wrapper around return value
  # Will be used for control flow and not actual error handling
  class Return < RuntimeError
    attr_reader :value

    def initialize(value)
      @value = value
    end
  end
end
