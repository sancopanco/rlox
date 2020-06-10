module Lox
  module Stmt
    class Print < Statement
      attr_reader :expr

      def initialize(expr)
        @expr = expr
      end

      def accept(visitor)
        visitor.visit_print_stmt(self)
      end
    end
  end
end
