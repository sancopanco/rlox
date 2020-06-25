module Lox
  module Expr
    # TODO: could that collide with ruby Set
    class Set < Expression
      attr_reader :object_expr, :name, :value_expr

      def initialize(object_expr, name, value_expr)
        @object_expr = object_expr
        @name = name
        @value_expr = value_expr
      end

      def accept(visitor)
        visitor.visit_set_expr(self)
      end
    end
  end
end
