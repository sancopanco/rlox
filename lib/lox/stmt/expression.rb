module Lox
  module Stmt
    class Expression < Statement
      attr_reader :expr

      def initialize(expr)
        @expr = expr
      end

      def accept(visitor)
        visitor.visit_expression_stmt(self)
      end
    end
  end
end
