module Lox
  # Lox runtime errors
  # identifies where in the user's code the runtime error came from
  class RuntimeError < ::RuntimeError
    attr_reader :token

    def initialize(token, message)
      super(message)
      @token = token
    end
  end
end
