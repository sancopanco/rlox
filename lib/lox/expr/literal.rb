module Lox
  module Expr
    # The leaves of an expression tree -- the atomic bits of syntax
    # that all other expressions are composed of
    class Literal < Expression
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def accept(visitor)
        visitor.visit_literal_expr(self)
      end
    end
  end
end
