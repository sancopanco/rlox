module Lox
  module Expr
    # Logical operators -- and, or
    # Each have their own precedence with `or` lower than `and`
    class Logical < Expression
      attr_reader :left_expr, :right_expr, :operator

      def initialize(left_expr, operator, right_expr)
        @left_expr = left_expr
        @right_expr = right_expr
        @operator = operator
      end

      def accept(visitor)
        visitor.visit_logical_expr(self)
      end
    end
  end
end
