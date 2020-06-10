module Lox
  module Expr
    # A Grouping node has a reference to an inner node
    # the expression contained inside the parantheses
    class Grouping < Expression
      attr_reader :expr

      def initialize(expr)
        @expr = expr
      end

      def accept(visitor)
        visitor.visit_grouping_expr(self)
      end
    end
  end
end
