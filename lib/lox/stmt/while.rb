module Lox
  module Stmt
    class While < Statement
      attr_reader :condition_expr, :body_stmt

      def initialize(condition_expr, body_stmt)
        @condition_expr = condition_expr
        @body_stmt = body_stmt
      end

      def accept(visitor)
        visitor.visit_while_stmt(self)
      end
    end
  end
end
