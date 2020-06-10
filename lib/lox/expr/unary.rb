module Lox
  module Expr
    class Unary < Expression
      attr_reader :operator, :right_expr
      def initialize(operator, right_expr)
        @operator = operator
        @right_expr = right_expr
      end

      def accept(visitor)
        visitor.visit_unary_expr(self)
      end
    end
  end
end
