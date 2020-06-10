module Lox
  module Stmt
    attr_reader :name, :initializer

    # Variable declaration
    # It stores the name token, along with the initializer expression
    class Var < Statement
      attr_reader :initializer, :name

      def initialize(name, initializer)
        @name = name
        @initializer = initializer
      end

      def accept(visitor)
        visitor.visit_var_stmt(self)
      end
    end
  end
end
