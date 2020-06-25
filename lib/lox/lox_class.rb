module Lox
  class LoxClass
    include Callable

    attr_reader :name, :methods_table

    # Class stores behaviour, instance stores states
    # LoxInstance has its map of fields, LoxClass gets a map of methods
    # methods_table, key: method_name, value: LoxFunction instance
    def initialize(name, methods_table)
      @name = name
      @methods_table = methods_table
    end

    # It instantiates a new lox instance for the called class ad return it
    # When a class is called, after the LoxInstance is created, we look for an 'init' method
    # If we find one, we immediately bind and invoke it just like a normal method call
    # The argument list is forwarded along
    # Since we bind the `init` method before we call it, it has access to `this` inside its body
    # That, along with arguments passed to the class, is all you need to be able to set up the new instance
    # And return that new instance for the called class
    def call(interpreter, arguments)
      instance = LoxInstance.new(self)

      initializer = find_method('init')
      initializer.bind(instance).call(interpreter, arguments) unless initializer.nil?

      instance
    end

    # Interpreter validates that you passed the right amount of arguments to a callable
    # If there is an initializer, that medhod's arity determines how many arguments you pass when you call a class -- to create an instance
    # It's not a requirement for a class to define an initializer, if you don’t have an initializer, the arity is still zero
    def arity
      initializer = find_method('init')
      return 0 if initializer.nil?
      initializer.arity
    end

    # Look up on the class's methods table
    def find_method(name)
      methods_table[name] if methods_table.key?(name)
      nil
    end

    def to_s
      name
    end
  end
end
