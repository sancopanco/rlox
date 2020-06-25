module Lox
  module Expr
    class This < Expression
      attr_reader :keyword

      def initialize(keyword)
        @keyword = keyword
      end

      def accept(visitor)
        visitor.visit_this_expr(self)
      end
    end
  end
end
