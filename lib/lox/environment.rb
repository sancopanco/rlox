module Lox
  # Bindings that associate variables to values need to be stored
  # keys are variable names, and the values are the variable's values
  class Environment
    attr_reader :enclosing

    def initialize(enclosing = nil)
      # to store the bindings
      @values = {}

      # We give each environment a reference to its enclosing one -- cactus stack, spaghetti stack
      # enclosing = nil -- global scope
      # otherwise, creates a new local scope inside the given outer one
      @enclosing = enclosing
    end

    # A variable defination binds a name to value
    # We don't check if it's already present
    # that brings a semantic a choice -- redefining an existing variable is possible
    # Scheme allows redefining variables at the top level
    # We'll allow it -- at least for the global variables
    def define(name, value)
      values[name] = value
    end

    # Once a variable exists, we need a way to look it up
    # If the variable is found, it returns the value bound to it
    # if not, report a runtime error
    # Making it a static error to mention a variable before it's been declared,
    # it becomes harder to define recursive procedures that call each other
    # You can refer to variable in a chunk of code without immediately evaluating it
    # if that chunk of code is wrapped inside of a function.
    # It is OK to refer to variable name before it's defined as long as you don't  evaluate the reference
    # Some languages(Java, C#) declares all of the names before looking at the bodies of any of the functions
    # C don't do that, forces you to add forward declarations to declare a name before it's fully defined
    # variable lookup and assignment need to walk to chain
    def get(name_token)
      return values[name_token.lexeme] if values.key?(name_token.lexeme)
      # walk the chain
      return enclosing.get(name_token) unless enclosing.nil?
      raise RuntimeError.new(name_token, "Undefined variable #{name_token.lexeme} .")
    end

    # Assignment
    # Assignment is not allowed to create a new variable,
    # it is a runtime error if the name does not already exist in the environment
    # Unlike Ruby and Python
    # If the variable isn’t found in this scope, we simply try the enclosing one.
    def assign(name, value)
      if values.key?(name.lexeme)
        values[name.lexeme] = value
        return
      end

      unless enclosing.nil?
        enclosing.assign(name, value)
        return
      end
      raise RuntimeError.new(name, "Undefined variable #{name.lexeme} .")
    end

    private

    attr_accessor :values
  end
end
