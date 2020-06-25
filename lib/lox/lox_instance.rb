module Lox
  # A runtime representation of an instance of a Lox class
  class LoxInstance
    attr_reader :klass, :fields

    def initialize(klass)
      @klass = klass
      # Each key in the map is a property name, and the corresponding value is the prop's value
      @fields = {}
    end

    # To lookup a property on an instance
    # Return if the instance has a field with given name. Otherwise, it raises an error
    # Even though methods are owned by the class, they are still accessible through instances of that class
    # When looking up a property on an instance, if don't find a matching field, we look for a method with that name on the instance's class
    # Looking for a field first implies that fields shadow methods
    def get(name)
      puts fields
      return fields[name.lexeme] if fields.key?(name.lexeme)

      # Method lookup
      method = klass.find_method(name.lexeme)

      # self LoxInstance
      # At runtime, we create the environment after we find the method on the instance
      return method.bind(self) unless method.nil?

      raise RuntimeError.new(name, "Undefined property #{name.lexeme} .")
    end

    # There is no check to see if it key(name) is already present
    # We allow freely creating new fields on the instance
    def set(name, value)
      puts [name, value, @fields].inspect
      @fields[name] = value
    end

    def to_s
      "#{klass.name} instance"
    end
  end
end
