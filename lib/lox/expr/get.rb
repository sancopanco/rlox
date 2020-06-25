module Lox
  module Expr
    class Get < Expression
      attr_reader :object_expr, :name

      def initialize(object_expr, name)
        @object_expr = object_expr
        @name = name
      end

      def accept(visitor)
        visitor.visit_get_expr(self)
      end
    end
  end
end
