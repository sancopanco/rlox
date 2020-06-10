module Lox
  module Expr
    # Variable access expressions for accessing a variable
    class Variable < Expression
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def accept(visitor)
        visitor.visit_variable_expr(self)
      end
    end
  end
end
