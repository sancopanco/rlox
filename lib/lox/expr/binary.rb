module Lox
  module Expr
    class Binary < Expression
      attr_reader :operator, :left_expr, :right_expr

      def initialize(left_expr, operator, right_expr)
        @left_expr = left_expr
        @right_expr = right_expr
        @operator = operator # token
      end

      def accept(visitor)
        visitor.visit_binary_expr(self)
      end
    end
  end
end
