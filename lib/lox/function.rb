require_relative 'return'
module Lox
  class Function
    include Callable

    attr_reader :function_declaration, :closure

    def initialize(function_declaration, closure)
      @function_declaration = function_declaration
      # Closure being set during the function decleration
      @closure = closure
    end

    def call(interpreter, arguments)
      # Each function call gets its own environment -- where it stores parameters
      # Otherwise, recursion would break
      # This environment must be created dynamically
      # If there are multiple calls to the same function in play at the same time,
      # each needs its own environment, even though they all call to the same function
      # closure represents the lexical scope surrounding the function decleration,
      # when called it uses that, it uses that environment, instead of globals
      environment = Environment.new(closure)

      # For eacg pair(parameter, argument), creates a new variable with the parameter's name
      # and binds it to the argument's value
      # Up until now, the current environment was the environmet where the function was being called
      # Now, we teleport from there inside new parameter space we've created for the function
      function_declaration.params.each_index do |i|
        environment.define(function_declaration.params[i].lexeme, arguments[i])
      end

      # Tell interpreter to execute the body of the function in this new function-local environment
      # Once the body of the function has finished executing, `execute_block` discards that function
      # local environment and restores the previous one that was active before back at the callsite

      begin
        interpreter.execute_block(function_declaration.body, environment)
      rescue Return => return_value
        return return_value.value
      end

      nil
    end

    def arity
      function_declaration.params.size
    end

    # If user prints a functio value
    def to_s
      "<fn #{function_declaration.name.lexeme}>"
    end
  end
end
